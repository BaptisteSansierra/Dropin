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
                  tagImport: Bool,
                  tagName: String,
                  progress: @MainActor @Sendable (Int) -> Void,
                  canceled: @MainActor @Sendable () -> Void,
                  completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws {
        try await `import`(plan, mapping: [],
                           tagImport: tagImport,
                           tagName: tagName,
                           progress: progress,
                           canceled: canceled,
                           completion: completion)
    }

    /// Richer entry point used when the file has tags: `mapping` is the user's tag-to-category choices from MapstrCategoriesView
    /// (empty mapping = the protocol-level `import` above, i.e. no tags or none converted).
    func `import`(_ plan: MapstrImportPlan,
                  mapping: CategoryMapping,
                  tagImport: Bool,
                  tagName: String,
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
            try await createLocalItems(plan,
                                       mapping: mapping,
                                       tagImport: tagImport,
                                       tagName: tagName,
                                       progress: progress)
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
                                  tagImport: Bool,
                                  tagName: String,
                                  progress: @MainActor @Sendable (Int) -> Void) async throws {
        // Every entity created by this import run shares the same instant.
        let importDate = Date()
        let resolutions = plan.resolve(mapping)
        let resolutionByPlaceID = Dictionary(uniqueKeysWithValues: resolutions.map { ($0.placeID, $0) })
        let targetByTagID = Dictionary(mapping.map { ($0.tagID, $0.target) }, uniquingKeysWith: { first, _ in first })
        let tagByID = Dictionary(plan.tags.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let importTagName = tagImport ? tagName.trimmedName.nonEmpty : nil

        // Create all places
        var upsertCount = 0
        for place in plan.places {
            try Task.checkCancellation()
            guard let resolution = resolutionByPlaceID[place.id] else { continue }
            try await processPlace(place,
                                   resolution: resolution,
                                   targetByTagID: targetByTagID,
                                   tagByID: tagByID,
                                   importTagName: importTagName,
                                   importDate: importDate)
            upsertCount += 1
            await progress(upsertCount)
        }
    }

    private func processPlace(_ place: MapstrPlace,
                              resolution: PlaceResolution,
                              targetByTagID: [String: CategoryConversion.Target],
                              tagByID: [String: MapstrTag],
                              importTagName: String?,
                              importDate: Date) async throws {
        // Avoid creating duplicates
        guard firstPlaceDuplicate(name: place.name, coordinates: place.coordinates) == nil else {
            duplicatePlacesCount += 1
            // NOTE: the place from import is ignored as an existing place was found
            //       The existing place is NOT updated with the imported place attributed
            return
        }

        // Category and tags are resolved for created places only: an unused one is never created
        var category: Category?
        if let target = resolution.categoryTagID.flatMap({ targetByTagID[$0] }) {
            switch target {
                case .existing(let categoryID):
                    category = existingCategories.first(where: { $0.id == categoryID })
                    if category == nil {
                        Log.warning("MAPSTR import: existing category \(categoryID) not found for place \(place.name)")
                    }
                case .new(let name, let color, let icon):
                    category = try await resolveCategory(Category(name: name, color: color, icon: icon,
                                                                  importedAt: importDate, importSrc: .mapstr))
            }
        }
        var tags: [Tag] = []
        for mapstrTag in resolution.keptTagIDs.compactMap({ tagByID[$0] }) {
            let tag = try await resolveTag(Tag(name: mapstrTag.name, color: mapstrTag.color,
                                               importedAt: importDate, importSrc: .mapstr))
            if !tags.contains(tag) { tags.append(tag) }
        }
        if let importTagName {
            let tag = try await resolveTag(Tag(name: importTagName, color: String.randomColor(),
                                               importedAt: importDate, importSrc: .mapstr))
            if !tags.contains(tag) { tags.append(tag) }
        }

        let newPlace = Place(id: UUID(),
                             name: place.name,
                             coordinates: place.coordinates,
                             address: place.address,
                             tags: tags,
                             category: category,
                             icon: place.icon,
                             notes: place.notes,
                             importedAt: importDate,
                             importSrc: .mapstr)

        // Created place is added to existing places array so we ensure there's no duplicates in the file
        existingHardPlaces.append(newPlace)

        try await upsertPlace(newPlace, shouldSave: false)
        createdPlacesCount += 1
    }

    /// The active category named like `candidate` (`nameKey`), else `candidate` once created
    private func resolveCategory(_ candidate: Category) async throws -> Category {
        if let existing = existingCategories.firstActive(named: candidate.name) { return existing }
        let category = candidate.trimmingName()
        try await upsertCategory(category, shouldSave: false)
        existingCategories.append(category)
        createdCategoriesCount += 1
        return category
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
