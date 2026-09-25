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
    private let fetchGroups: FetchGroups
    private let fetchTags: FetchTags
    private let upsertPlace: UpsertPlace
    private let upsertGroup: UpsertGroup
    private let upsertTag: UpsertTag
    private let markerGroupName: String

    private var existingHardPlaces: [PlaceEntity] = []  // contains all the non-deleted existing places on disk
    private var existingGroups: [GroupEntity] = []      // contains all the existsing groups on disk
    private var existingTags: [TagEntity] = []          // contains all the existsing tags on disk
    private var duplicatePlacesCount: Int = 0
    private var createdPlacesCount: Int = 0
    private var createdTagsCount: Int = 0

    init(saveContext: SaveContext,
         rollbackContext: RollbackContext,
         fetchPlaces: FetchPlaces,
         fetchGroups: FetchGroups,
         fetchTags: FetchTags,
         upsertPlace: UpsertPlace,
         upsertGroup: UpsertGroup,
         upsertTag: UpsertTag,
         markerGroupName: String) {
        self.saveContext = saveContext
        self.rollbackContext = rollbackContext
        self.fetchPlaces = fetchPlaces
        self.fetchGroups = fetchGroups
        self.fetchTags = fetchTags
        self.upsertPlace = upsertPlace
        self.upsertGroup = upsertGroup
        self.upsertTag = upsertTag
        self.markerGroupName = markerGroupName
    }

    func execute(_ url: URL,
                 onPlacesCountResolved: @MainActor @Sendable (Int) -> Void,
                 progress: @MainActor @Sendable (Int) -> Void,
                 canceled: @MainActor @Sendable () -> Void,
                 completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws {
        // Handle the security scoping since the file lives outside sandbox
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        // Read file
        let data = try Data(contentsOf: url)
        try await execute(data,
                          onPlacesCountResolved: onPlacesCountResolved,
                          progress: progress,
                          canceled: canceled,
                          completion: completion)
    }
    
    func execute(_ data: Data,
                 onPlacesCountResolved: @MainActor @Sendable (Int) -> Void,
                 progress: @MainActor @Sendable (Int) -> Void,
                 canceled: @MainActor @Sendable () -> Void,
                 completion: @MainActor @Sendable (Int, Int, Int, Int) -> Void) async throws {

        // Fetch existing
        existingHardPlaces = try await fetchPlaces()
            .filter { $0.isActive }
        existingTags = try await fetchTags()
        existingGroups = try await fetchGroups()

        guard !Task.isCancelled else { await cancel(canceled); return }

        // Decode data
        let collection = try decode(data)
        guard collection.features.count > 0 else {
            throw ImportError.emptyFile
        }
        guard !Task.isCancelled else { await cancel(canceled); return }
        Log.info("Found \(collection.features.count) Mapstr places")
        await onPlacesCountResolved(collection.features.count)

        // Create items
        do {
            try await createLocalItems(collection, progress: progress)
        } catch is CancellationError {
            await cancel(canceled)
        }
        
        // Persist items and complete
        guard !Task.isCancelled else { return }
        try await saveContext()
        
        Log.info(" -> persisted")
        await completion(createdPlacesCount, duplicatePlacesCount, 0, createdTagsCount)
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
        let tags: [MapstrTag]?
    }

    private struct MapstrTag: Decodable {
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

    private func createLocalItems(_ collection: FeatureCollection, progress: @MainActor @Sendable (Int) -> Void) async throws {
        // Create marker Group:
        //   all mapstr places are grouped under a specific mapstr group, it must not exists already
        if let existing = existingGroups.first(where: { $0.name == markerGroupName }), existing.isActive {
            throw ImportError.markerExists(markerGroupName)
        }
        let markerGroup = GroupEntity(name: markerGroupName,
                                      color: String.randomColor(),
                                      icon: .sf("square.and.arrow.down"))
        try await upsertGroup(markerGroup, shouldSave: false)

        // Create all tags found in mapstr file
        var tagsByName: [String: (tag: TagEntity, exists: Bool)] = [:]
        for feature in collection.features {
            for mapstrTag in feature.properties.tags ?? [] {
                try Task.checkCancellation()
                
                if tagsByName[mapstrTag.name] == nil {
                    if let existingTag = existingTags.first(where: { item in item.name == mapstrTag.name }),
                       existingTag.isActive {
                        // Avoid creating duplicated tags appart if it was deleted
                        tagsByName[mapstrTag.name] = (tag: existingTag,
                                                      exists: true)
                        
                        //if existingTag.deletedAt != nil {
                        //    // In case tags exists dut sof deleted, we needa reactivate it
                        //    try await upsertTag(existingTag.undeleted(), shouldSave: false)
                        //    // Increment created tag counter
                        //    createdTagsCount += 1
                        //}
                    } else {
                        let newTag = TagEntity(name: mapstrTag.name, color: mapstrTag.color)
                        tagsByName[mapstrTag.name] = (tag: newTag,
                                                      exists: false)
                        existingTags.append(newTag)
                        // Increment created tag counter
                        createdTagsCount += 1
                    }
                }
            }
        }
        for item in tagsByName.values {
            try Task.checkCancellation()
            if !item.exists {
                try await upsertTag(item.tag, shouldSave: false)
            }
        }
        
        // Create all places
        var upsertCount = 0
        for feature in collection.features {
            try Task.checkCancellation()
            // process place
            try await processFeature(feature, markerGroup: markerGroup, tagsByName: tagsByName)
            // and increment
            upsertCount += 1
            await progress(upsertCount)
        }
    }
    
    private func processFeature(_ feature: Feature,
                                markerGroup: GroupEntity,
                                tagsByName: [String: (tag: TagEntity, exists: Bool)]) async throws {
        guard feature.geometry.coordinates.count >= 2 else { return }
        let coords = CLLocationCoordinate2D(latitude: feature.geometry.coordinates[1],
                                            longitude: feature.geometry.coordinates[0])
        
        // Avoid creating duplicates
        guard firstPlaceDuplicate(name: feature.properties.name, coordinates: coords) == nil else {
            duplicatePlacesCount += 1
            // NOTE: the place from import is ignored as an existing place was found
            //       The existing place is NOT updated with the imported place attributed
            return
        }
        
        let placeTags = (feature.properties.tags ?? []).compactMap { tagsByName[$0.name]?.tag }
        
        //if feature.properties.name != "Porte Dauphine" {
        //    Log.debug("SKIP Place \(feature.properties.name)")
        //    continue
        //}
        
        let place = PlaceEntity(id: UUID(),
                                name: feature.properties.name,
                                coordinates: coords,
                                address: feature.properties.address,
                                tags: placeTags,
                                group: markerGroup,
                                icon: Self.mapIcon(feature.properties.icon),
                                notes: feature.properties.userComment)
        
        // Created place is added to existing places array so we ensure there's nu duplicates in the file
        existingHardPlaces.append(place)
        
        // Add to database
        try await upsertPlace(place, shouldSave: false)
        createdPlacesCount += 1
    }
    
    private func firstPlaceDuplicate(name: String, coordinates: CLLocationCoordinate2D) -> PlaceEntity? {
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
