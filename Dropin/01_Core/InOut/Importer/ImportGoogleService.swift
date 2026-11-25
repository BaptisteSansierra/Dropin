//
//  ImportGoogleService.swift
//  Dropin
//
//  Created by baptiste sansierra on 21/11/26.
//

import Foundation
import CoreLocation
import ContactFieldKit

private struct GeoJSONGGProperties: Decodable {
    let date: String
    /// `rating` is only defined in Reviews.json
    let rating: Int?
    let googleUrl: String
    /// `location` is optional, some places have only a URL
    let location: GeoJSONGGLocation?
    /// `comment` is only defined in "Saved Places.json" and for a Place with coordinates (0, 0).
    /// "No location information is available for this saved place"
    /// No other value seen
    let comment: String?
    /// `review` is only defined in Reviews.json
    let review: String?
    
    enum CodingKeys: String, CodingKey {
        case date
        case rating = "five_star_rating_published"
        case googleUrl = "google_maps_url"
        case location
        case comment = "Comment"
        case review = "review_text_published"
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decode(String.self, forKey: .date)
        rating = try c.decodeIfPresent(Int.self, forKey: .rating)
        googleUrl = try c.decode(String.self, forKey: .googleUrl)
        location = try c.decodeIfPresent(GeoJSONGGLocation.self, forKey: .location)
        comment = try c.decodeIfPresent(String.self, forKey: .comment)
        review = try c.decodeIfPresent(String.self, forKey: .review)
    }
}

private struct GeoJSONGGLocation: Decodable {
    let name: String
    let address: String
    let countryCode: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case address
        case countryCode = "country_code"
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        address = try c.decode(String.self, forKey: .address)
        countryCode = try c.decodeIfPresent(String.self, forKey: .countryCode)
    }
}


actor ImportGoogleService: ImportServiceProtocol {
        
    // MARK: - Private Properties
    private let saveContext: SaveContext
    private let rollbackContext: RollbackContext
    private let fetchPlaces: FetchPlaces
    private let fetchCategories: FetchCategories
    private let fetchTags: FetchTags
    private let upsertPlace: UpsertPlace
    private let upsertCategory: UpsertCategory
    private let upsertTag: UpsertTag
 
    private var existingHardPlaces: [Place] = []      // contains all the non-deleted existing places on disk
    //private var existingCategories: [Category] = []   // contains all the existsing categories on disk
    private var existingTags: [Tag] = []              // contains all the existsing tags on disk
    private var duplicatePlacesCount: Int = 0
    private var createdPlacesCount: Int = 0
    private var createdTagsCount: Int = 0
    //private var createdCategoriesCount: Int = 0

    // MARK: - Init
    init(saveContext: SaveContext,
         rollbackContext: RollbackContext,
         fetchPlaces: FetchPlaces,
         fetchCategories: FetchCategories,
         fetchTags: FetchTags,
         upsertPlace: UpsertPlace,
         upsertCategory: UpsertCategory,
         upsertTag: UpsertTag) {
        self.saveContext = saveContext
        self.rollbackContext = rollbackContext
        self.fetchPlaces = fetchPlaces
        self.fetchCategories = fetchCategories
        self.fetchTags = fetchTags
        self.upsertPlace = upsertPlace
        self.upsertCategory = upsertCategory
        self.upsertTag = upsertTag
    }
    
    // MARK: - Phase 1: read (parse only, writes nothing)

    func read(_ url: URL) async throws -> GoogleImportPlan {
        // Handle the security scoping since the file lives outside sandbox
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        return try await read(data)
    }
    
    func read(_ data: Data) async throws -> GoogleImportPlan {
        var collection: GeoJSONFeatureCollection<GeoJSONGGProperties>
        do {
            collection = try GeoJSONFeatureCollection<GeoJSONGGProperties>.decode(data)
        } catch {
            throw error
        }
        guard collection.features.count > 0 else {
            throw ImportError.emptyFile
        }
        Log.info("Found \(collection.features.count) GoogleMaps places")

        var places: [GooglePlace] = []
        
        for (_, feature) in collection.features.enumerated() {
            guard feature.geometry.coordinates.count >= 2 else { continue }
            var coords = feature.geometry.coordinate
            var googlePlace: GooglePlace?
            if coords.isNull() {
                // Some google urls contain coordinates: "http://maps.google.com/?q=42.81687794930286,-1.6456934809684753",
                guard let coordsFromUrl = feature.properties.googleUrl.coordinateFromGoogleMapsURL else {
                    // Skip it, we have nothing about this place, only an opaque google url
                    continue
                }
                Log.debug("Exctracted coords from \(feature.properties.googleUrl)")
                coords = coordsFromUrl
                // We extracted coord from the url, create a place from it, no data, just a pin, give it a name
                let droppedPin = String(localized: LocalizedStringResource("common.from_google_maps.unnamed"))
                googlePlace = GooglePlace(id: UUID(),
                                          name: droppedPin,
                                          coordinates: coords,
                                          address: nil,
                                          url: feature.properties.googleUrl,
                                          review: nil,
                                          rating: nil)
            }
            if let location = feature.properties.location {
                googlePlace = GooglePlace(id: UUID(),
                                          name: location.name,
                                          coordinates: coords,
                                          address: location.address,
                                          url: feature.properties.googleUrl,
                                          review: feature.properties.review,
                                          rating: feature.properties.rating)
            }
            if let googlePlace = googlePlace {
                places.append(googlePlace)
            }
        }
        return GoogleImportPlan(places: places)
    }

    // MARK: - Phase 2: import (writes)

    func `import`(_ plan: GoogleImportPlan,
                  tagImport: Bool,
                  tagName: String,
                  progress: @MainActor @Sendable (Int) -> Void,
                  canceled: @MainActor @Sendable () -> Void,
                  completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws {
        
        // Fetch existing
        existingHardPlaces = try await fetchPlaces()
            .filter { $0.isActive }
        //existingCategories = try await fetchCategories()
        //    .filter { $0.isActive }
        existingTags = try await fetchTags()
            .filter { $0.isActive }

        guard !Task.isCancelled else { await cancel(canceled); return }

        // Create items
        do {
            try await createLocalItems(plan,
                                       tagImport: tagImport,
                                       tagName: tagName,
                                       progress: progress)
        } catch is CancellationError {
            await cancel(canceled);
        }

        // Persist items and complete
        guard !Task.isCancelled else { return }
        try await saveContext()
        Log.info(" -> persisted")
        await completion(createdPlacesCount, duplicatePlacesCount, 0, createdTagsCount)

    }
    
    private func createLocalItems(_ plan: GoogleImportPlan,
                                  tagImport: Bool,
                                  tagName: String,
                                  progress: @MainActor @Sendable (Int) -> Void) async throws {
        // Every entity created by this import run shares the same instant.
        let importDate = Date()
        let importTagName = tagImport ? tagName.trimmedName.nonEmpty : nil

        // Create all places
        var upsertCount = 0
        for place in plan.places {
            try Task.checkCancellation()
            try await processPlace(place,
                                   importTagName: importTagName,
                                   importDate: importDate)
            upsertCount += 1
            await progress(upsertCount)
        }
    }
    
    private func processPlace(_ gPlace: GooglePlace,
                              importTagName: String?,
                              importDate: Date) async throws {
        // Avoid creating duplicates
        guard firstPlaceDuplicate(name: gPlace.name, coordinates: gPlace.coordinates) == nil else {
            duplicatePlacesCount += 1
            // NOTE: the place from import is ignored as an existing place was found
            //       The existing place is NOT updated with the imported place attributed
            return
        }

        var tags: [Tag] = []
        if let importTagName {
            let tag = try await resolveTag(Tag(name: importTagName, color: String.randomColor(),
                                               importedAt: importDate, importSrc: .google))
            if !tags.contains(tag) { tags.append(tag) }
        }
        let url = ContactItem.url(gPlace.url, label: .custom(String(localized: "common.from_google_maps")))
        let place = Place(id: UUID(),
                          name: gPlace.name,
                          coordinates: gPlace.coordinates,
                          address: gPlace.address,
                          address2: nil,
                          tags: tags,
                          category: nil,
                          icon: nil,
                          rating: gPlace.rating == nil ? nil : Float(gPlace.rating!),
                          phone: [],
                          email: [],
                          url: [url.rawValue],
                          notes: gPlace.review,
                          createdAt: importDate,
                          updatedAt: importDate,
                          deletedAt: nil,
                          importedAt: importDate,
                          importSrc: .google)
        
        // Created place is added to existing places array so we ensure there's no duplicates in the file
        existingHardPlaces.append(place)

        // Add to database
        try await upsertPlace(place, shouldSave: false)
        createdPlacesCount += 1
    }
    
    // MARK: - Persistence
    private func cancel(_ canceled: @MainActor @Sendable () -> Void) async {
        Log.info("GoogleMaps import canceled")
        await rollbackContext()
        await canceled()
    }
    
    private func firstPlaceDuplicate(name: String, coordinates: CLLocationCoordinate2D) -> Place? {
        for place in existingHardPlaces {
            if place.isIdentical(name: name, coords: coordinates) && place.isActive {
                Log.warning("duplicate found: \(name) > \(place.name) id:\(place.id)")
                return place
            }
        }
        return nil
    }
    
    /// The active tag named like `candidate` (`nameKey`), else `candidate` once created
    private func resolveTag(_ candidate: Tag) async throws -> Tag {
        if let existing = existingTags.firstActive(named: candidate.name) { return existing }
        let tag = candidate.trimmingName()
        try await upsertTag(tag, shouldSave: false)
        existingTags.append(tag)
        createdTagsCount += 1
        return tag
    }
}
