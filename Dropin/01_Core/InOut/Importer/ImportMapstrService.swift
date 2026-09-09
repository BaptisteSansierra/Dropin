//
//  ImportMapstrService.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import Foundation
import CoreLocation

actor ImportMapstrService: ImportServiceProtocol {

    private let upsertPlace: UpsertPlace
    private let upsertTag: UpsertTag
    private let markerTagName: String

    init(upsertPlace: UpsertPlace, upsertTag: UpsertTag, markerTagName: String) {
        self.upsertPlace = upsertPlace
        self.upsertTag = upsertTag
        self.markerTagName = markerTagName
    }

    func execute(_ url: URL,
                 onPlacesCountResolved: @MainActor @Sendable (Int) -> Void,
                 progress: @MainActor @Sendable (Int) -> Void,
                 canceled: @MainActor @Sendable () -> Void,
                 completion: @MainActor @Sendable (Int) -> Void) async throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        // Read file
        let data = try Data(contentsOf: url)
        guard !Task.isCancelled else { await cancel(canceled); return }

        // Decode data
        let collection = try decode(data)
        guard !Task.isCancelled else { await cancel(canceled); return }
        Log.info("Found \(collection.features.count) Mapstr places")
        await onPlacesCountResolved(collection.features.count)

        // Create items
        do {
            try await persist(collection, progress: progress)
        } catch is CancellationError {
            await cancel(canceled)
        }
        guard !Task.isCancelled else { return }
        Log.info(" -> persisted")
        await completion(collection.features.count)
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
        
        await canceled()
    }

    private func persist(_ collection: FeatureCollection, progress: @MainActor @Sendable (Int) -> Void) async throws {
        
        // All mapstr places are tagged with a specific mapstr tag, create this tag
        let markerTag = TagEntity(name: markerTagName, color: "#FF9500")
        try await upsertTag(markerTag)

        // Create all tags found in mapstr file
        var tagsByName: [String: TagEntity] = [:]
        for feature in collection.features {
            for mapstrTag in feature.properties.tags ?? [] {
                try Task.checkCancellation()
                if tagsByName[mapstrTag.name] == nil {
                    tagsByName[mapstrTag.name] = TagEntity(name: mapstrTag.name, color: mapstrTag.color)
                }
            }
        }
        for tag in tagsByName.values {
            try Task.checkCancellation()
            try await upsertTag(tag)
        }

        // Create all places
        var upsertCount = 0
        for feature in collection.features {
            try Task.checkCancellation()
            guard feature.geometry.coordinates.count >= 2 else { continue }
            let placeTags = (feature.properties.tags ?? []).compactMap { tagsByName[$0.name] }
            let place = PlaceEntity(id: UUID(),
                                    name: feature.properties.name,
                                    coordinates: CLLocationCoordinate2D(
                                        latitude: feature.geometry.coordinates[1],
                                        longitude: feature.geometry.coordinates[0]
                                    ),
                                    address: feature.properties.address ?? "",
                                    tags: [markerTag] + placeTags,
                                    icon: Self.mapIcon(feature.properties.icon))
            try await upsertPlace(place)
            upsertCount += 1
            await progress(upsertCount)
        }
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


#if false
@MainActor
struct ImportMapstrService: ImportServiceProtocol {

    private let upsertPlace: UpsertPlace
    private let upsertTag: UpsertTag
    private let markerTagName: String

    init(upsertPlace: UpsertPlace, upsertTag: UpsertTag, markerTagName: String) {
        self.upsertPlace = upsertPlace
        self.upsertTag = upsertTag
        self.markerTagName = markerTagName
    }

    func execute(_ url: URL,
                 onPlacesCountResolved: ((Int) -> Void),
                 progress: ((Int) -> Void),
                 completion: ((Int) -> Void)) async throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let collection = try decode(data)
        Log.info("Found \(collection.features.count) Mapstr places")
        onPlacesCountResolved(collection.features.count)
        try await persist(collection, progress: progress)
        Log.info(" -> persisted")
        completion(collection.features.count)
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

    private func persist(_ collection: FeatureCollection, progress: ((Int) -> Void)) async throws {
        let markerTag = TagEntity(name: markerTagName, color: "#FF9500")
        try await upsertTag(markerTag)

        var tagsByName: [String: TagEntity] = [:]
        for feature in collection.features {
            for mapstrTag in feature.properties.tags ?? [] {
                if tagsByName[mapstrTag.name] == nil {
                    tagsByName[mapstrTag.name] = TagEntity(name: mapstrTag.name, color: mapstrTag.color)
                }
            }
        }
        for tag in tagsByName.values {
            try await upsertTag(tag)
        }

        var upsertCount = 0
        for feature in collection.features {
            guard feature.geometry.coordinates.count >= 2 else { continue }
            let placeTags = (feature.properties.tags ?? []).compactMap { tagsByName[$0.name] }
            let place = PlaceEntity(id: UUID(),
                                    name: feature.properties.name,
                                    coordinates: CLLocationCoordinate2D(
                                        latitude: feature.geometry.coordinates[1],
                                        longitude: feature.geometry.coordinates[0]
                                    ),
                                    address: feature.properties.address ?? "",
                                    tags: [markerTag] + placeTags,
                                    icon: Self.mapIcon(feature.properties.icon))
            try await upsertPlace(place)
            upsertCount += 1
            progress(upsertCount)
        }
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
#endif
