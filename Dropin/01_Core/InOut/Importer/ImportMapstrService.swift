//
//  ImportMapstrService.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import Foundation
import CoreLocation

actor ImportMapstrService: ImportServiceProtocol {

    private let saveContext: SaveContext
    private let rollbackContext: RollbackContext
    private let fetchPlaces: FetchPlaces
    private let fetchCategories: FetchCategories
    private let fetchTags: FetchTags
    private let upsertPlace: UpsertPlace
    private let upsertCategory: UpsertCategory
    private let upsertTag: UpsertTag

    private var existingHardPlaces: [Place] = []  // contains all the non-deleted existing places on disk
    private var existingCategories: [Category] = []      // contains all the existsing categories on disk
    private var existingTags: [Tag] = []          // contains all the existsing tags on disk
    private var duplicatePlacesCount: Int = 0
    private var createdPlacesCount: Int = 0
    private var createdTagsCount: Int = 0
    private var createdCategoriesCount: Int = 0

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

    func read(_ url: URL) async throws -> MapstrImportPlan {
        // Handle the security scoping since the file lives outside sandbox
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        return try await read(data)
    }

    func read(_ data: Data) async throws -> MapstrImportPlan {
        let collection = try decode(data)
        guard collection.features.count > 0 else {
            throw ImportError.emptyFile
        }
        Log.info("Found \(collection.features.count) Mapstr places")

        var tagPlaceCounts: [String: Int] = [:]
        var tagColors: [String: String] = [:]
        var places: [MapstrPlace] = []

        for (index, feature) in collection.features.enumerated() {
            guard feature.geometry.coordinates.count >= 2 else { continue }
            let coords = CLLocationCoordinate2D(latitude: feature.geometry.coordinates[1],
                                                longitude: feature.geometry.coordinates[0])
            let featureTags = feature.properties.tags ?? []
            for mapstrTag in featureTags {
                tagPlaceCounts[mapstrTag.name, default: 0] += 1
                tagColors[mapstrTag.name] = mapstrTag.color
            }
            places.append(MapstrPlace(id: String(index),
                                      name: feature.properties.name,
                                      coordinates: coords,
                                      address: feature.properties.address,
                                      icon: Self.mapIcon(feature.properties.icon),
                                      notes: feature.properties.userComment,
                                      tagIDs: featureTags.map(\.name)))
        }

        let tags = tagPlaceCounts.keys.sorted().map { name in
            MapstrTag(id: name,
                      name: name,
                      color: tagColors[name] ?? String.randomColor(),
                      placeCount: tagPlaceCounts[name]!)
        }

        return MapstrImportPlan(places: places, tags: tags)
    }

    // MARK: - Phase 2: import (writes)

    func `import`(_ plan: MapstrImportPlan,
                 progress: @MainActor @Sendable (Int) -> Void,
                 canceled: @MainActor @Sendable () -> Void,
                 completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws {
        try await `import`(plan, mapping: [], progress: progress, canceled: canceled, completion: completion)
    }

    /// Richer entry point used when the file has tags: `mapping` is the user's
    /// tag-to-category choices from MapstrCategoriesView (empty mapping = the
    /// protocol-level `import` above, i.e. no tags or none converted).
    func `import`(_ plan: MapstrImportPlan,
                  mapping: CategoryMapping,
                  progress: @MainActor @Sendable (Int) -> Void,
                  canceled: @MainActor @Sendable () -> Void,
                  completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws {
        // Fetch existing
        existingHardPlaces = try await fetchPlaces()
            .filter { $0.isActive }
        existingCategories = try await fetchCategories()
        existingTags = try await fetchTags()

        guard !Task.isCancelled else { await cancel(canceled); return }

        do {
            try await createLocalItems(plan, mapping: mapping, progress: progress)
        } catch is CancellationError {
            await cancel(canceled)
        }

        guard !Task.isCancelled else { return }
        try await saveContext()

        Log.info(" -> persisted")
        await completion(createdPlacesCount, duplicatePlacesCount, createdCategoriesCount, createdTagsCount)
    }

    // MARK: - GeoJSON decoding

    private struct FeatureCollection: Decodable {
        let features: [Feature]
    }

    private struct Feature: Decodable {
        let geometry: Geometry
        let properties: Properties
    }

    private struct Geometry: Decodable {
        let coordinates: [Double]
    }

    private struct Properties: Decodable {
        let name: String
        let address: String?
        let icon: String?
        let userComment: String?
        let tags: [MapstrFileTag]?
    }

    private struct MapstrFileTag: Decodable {
        let name: String
        let color: String
    }

    private func decode(_ data: Data) throws -> FeatureCollection {
        do {
            return try JSONDecoder().decode(FeatureCollection.self, from: data)
        } catch {
            throw ImportError.corrupted(error.localizedDescription)
        }
    }

    // MARK: - Persistence
    private func cancel(_ canceled: @MainActor @Sendable () -> Void) async {
        Log.info("MAPSTR import canceled")
        await rollbackContext()
        await canceled()
    }

    private func createLocalItems(_ plan: MapstrImportPlan,
                                  mapping: CategoryMapping,
                                  progress: @MainActor @Sendable (Int) -> Void) async throws {
        let resolutions = plan.resolve(mapping)
        let resolutionByPlaceID = Dictionary(uniqueKeysWithValues: resolutions.map { ($0.placeID, $0) })

        // Resolve (existing or newly-created) categories for every converted tag.
        var categoryByTagID: [String: Category] = [:]
        for conversion in mapping {
            try Task.checkCancellation()
            switch conversion.target {
                case .existing(let categoryID):
                    if let category = existingCategories.first(where: { $0.id == categoryID }) {
                        categoryByTagID[conversion.tagID] = category
                    } else {
                        Log.warning("MAPSTR import: existing category \(categoryID) not found for tag \(conversion.tagID)")
                    }
                case .new(let name, let color, let icon):
                    let category = Category(name: name, color: color, icon: icon)
                    try await upsertCategory(category, shouldSave: false)
                    existingCategories.append(category)
                    createdCategoriesCount += 1
                    categoryByTagID[conversion.tagID] = category
            }
        }

        // A tag is only ever created/reused if at least one place keeps it
        // (a converted tag that never loses creates no tag).
        let keptTagIDs = Set(resolutions.flatMap(\.keptTagIDs))
        var tagByID: [String: Tag] = [:]
        for tagID in keptTagIDs {
            try Task.checkCancellation()
            guard let mapstrTag = plan.tags.first(where: { $0.id == tagID }) else { continue }
            if let existingTag = existingTags.first(where: { $0.name.lemmaNormalized == mapstrTag.name.lemmaNormalized && $0.isActive }) {
                tagByID[tagID] = existingTag
            } else {
                let tag = Tag(name: mapstrTag.name, color: mapstrTag.color)
                try await upsertTag(tag, shouldSave: false)
                existingTags.append(tag)
                createdTagsCount += 1
                tagByID[tagID] = tag
            }
        }

        // Create all places
        var upsertCount = 0
        for place in plan.places {
            try Task.checkCancellation()
            guard let resolution = resolutionByPlaceID[place.id] else { continue }
            try await processPlace(place,
                                   resolution: resolution,
                                   categoryByTagID: categoryByTagID,
                                   tagByID: tagByID)
            upsertCount += 1
            await progress(upsertCount)
        }
    }

    private func processPlace(_ place: MapstrPlace,
                              resolution: PlaceResolution,
                              categoryByTagID: [String: Category],
                              tagByID: [String: Tag]) async throws {
        // Avoid creating duplicates
        guard firstPlaceDuplicate(name: place.name, coordinates: place.coordinates) == nil else {
            duplicatePlacesCount += 1
            // NOTE: the place from import is ignored as an existing place was found
            //       The existing place is NOT updated with the imported place attributed
            return
        }

        let category = resolution.categoryTagID.flatMap { categoryByTagID[$0] }
        let tags = resolution.keptTagIDs.compactMap { tagByID[$0] }

        let newPlace = Place(id: UUID(),
                             name: place.name,
                             coordinates: place.coordinates,
                             address: place.address,
                             tags: tags,
                             category: category,
                             icon: place.icon,
                             notes: place.notes)

        // Created place is added to existing places array so we ensure there's no duplicates in the file
        existingHardPlaces.append(newPlace)

        try await upsertPlace(newPlace, shouldSave: false)
        createdPlacesCount += 1
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

    // MARK: - Icon mapping

    private static func mapIcon(_ mapstrIcon: String?) -> Icon? {
        guard let mapstrIcon = mapstrIcon else { return nil }
        switch mapstrIcon {
            case "restaurant":                  return .sf("fork.knife")
            case "cafe":                        return .sf("cup.and.saucer")
            case "bar":                         return .fa("martini-glass-citrus")
            case "beer":                        return .fa("beer-mug-empty")
            case "fastfood":                    return .sf("takeoutbag.and.cup.and.straw")
            case "bakery":                      return .sf("birthday.cake")
            case "wine":                        return .sf("wineglass")
            case "nightclub":                   return .sf("figure.socialdance")
            case "music":                       return .sf("music.note")
            case "movies":                      return .sf("film")
            case "spectacle":                   return .fa("masks-theater")
            case "amusement":                   return .sf("gamecontroller")
            case "museum", "civic":             return .sf("building.columns")
            case "monument", "worship",
                 "worship_christian":           return .sf("building.columns")
            case "art_gallery":                 return .sf("photo.artframe")
            case "historic":                    return .sf("building.2")
            case "library":                     return .sf("book")
            case "school":                      return .sf("graduationcap")
            case "park", "forest":              return .sf("tree")
            case "gardening":                   return .sf("leaf")
            case "beach":                       return .sf("water.waves")
            case "camping":                     return .sf("tent")
            case "hospital":                    return .sf("cross.case")
            case "shopping", "supermarket":     return .sf("cart")
            case "shopping_women":              return .sf("bag")
            case "atm":                         return .sf("banknote")
            case "gas_station":                 return .sf("fuelpump")
            case "parking":                     return .sf("parkingsign.circle")
            case "airport", "travel":           return .sf("airplane")
            case "bus":                         return .sf("bus")
            case "train":                       return .sf("train.side.front.car")
            case "lodging":                     return .sf("bed.double")
            case "home":                        return .sf("house")
            case "business":                    return .sf("building.2")
            case "tourism":                     return .sf("info.circle")
            case "zoo":                         return .fa("paw")
            case "car":                         return .sf("car")
            case "stadium":                     return .sf("sportscourt")
            default:
                Log.warning("mapstr icon '\(mapstrIcon)' not handled")
                return nil
        }
    }
}
