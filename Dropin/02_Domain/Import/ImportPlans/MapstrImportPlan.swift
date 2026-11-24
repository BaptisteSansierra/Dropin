//
//  MapstrImportPlan.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/26.
//
//  Phase 1: (parse-only) output for a Mapstr import, and the pure resolution
//  logic shared by the category-mapping screen's live preview and the actual
//  Phase 2: write; using the same function for both guarantees the preview
//  always matches what gets written.
//

import Foundation
import CoreLocation

/// One place parsed from the Mapstr file. `id` is a synthetic, parse-time-only correlation key
/// it has no relationship to the UUID the place eventually gets persisted under.
struct MapstrPlace: Sendable {
    let id: String
    let name: String
    let coordinates: CLLocationCoordinate2D
    let address: String?
    let icon: Icon?
    let notes: String?
    let tagIDs: [String]
}

/// One tag parsed from the Mapstr file. `id` is the tag name, Mapstr has no separate tag identifier,
/// and tags are already deduplicated by name.
struct MapstrTag: Sendable, Hashable {
    let id: String
    let name: String
    let color: String
    let placeCount: Int
}

struct MapstrImportPlan: Sendable {
    let places: [MapstrPlace]
    let tags: [MapstrTag]
    
    /// For each place, the first converted tag in `mapping` order that the place has becomes its category.
    /// Every other tag stays a tag, including converted tags that lost
    /// e.g. priority Restaurants > Museums, a place tagged both gets category Restaurants and keeps tag Museums.
    func resolve(_ mapping: CategoryMapping) -> [PlaceResolution] {
        places.map { place in
            let categoryTagID = mapping.first { place.tagIDs.contains($0.tagID) }?.tagID
            let keptTagIDs = place.tagIDs.filter { $0 != categoryTagID }
            return PlaceResolution(placeID: place.id, categoryTagID: categoryTagID, keptTagIDs: keptTagIDs)
        }
    }

    /// Number of places with 2+ converted tags, shown live on the mapping screen.
    func conflictCount(_ mapping: CategoryMapping) -> Int {
        let convertedTagIDs = Set(mapping.map(\.tagID))
        return places.filter { place in
            place.tagIDs.filter { convertedTagIDs.contains($0) }.count >= 2
        }.count
    }
}

/// One checked tag's conversion target, in priority order (index 0 = highest priority).
struct CategoryConversion: Sendable {
    let tagID: String
    let target: Target

    enum Target: Sendable {
        /// Matched an existing category by name — read-only, Mapstr's tag color is ignored.
        case existing(categoryID: UUID)
        case new(name: String, color: String, icon: Icon)
    }
}

typealias CategoryMapping = [CategoryConversion]

/// The outcome for one place once a mapping is applied.
struct PlaceResolution: Sendable, Equatable {
    let placeID: String
    /// The winning converted tag, if any. `nil` means the place gets no category.
    let categoryTagID: String?
    /// Every other tag the place has, including converted tags that lost.
    let keptTagIDs: [String]
}
