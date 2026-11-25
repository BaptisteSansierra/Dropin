//
//  Domain_MapstrImportResolve.swift
//  DropinTests
//
//  Covers README "Done when": no mapping, single tag, conflict with
//  priority, loser kept as tag, unused converted tag creates no tag,
//  existing category/tag reuse doesn't change resolve's own output.
//

import Testing
import Foundation
import CoreLocation
@testable import Dropin

struct Domain_MapstrImportResolve {

    private func makePlace(id: String, tagIDs: [String]) -> MapstrPlace {
        MapstrPlace(id: id,
                   name: "Place \(id)",
                   coordinates: .barcelona,
                   address: nil,
                   icon: nil,
                   notes: nil,
                   tagIDs: tagIDs)
    }

    private func makeTag(_ id: String, placeCount: Int = 1) -> MapstrTag {
        MapstrTag(id: id, name: id, color: "FF0000", placeCount: placeCount)
    }

    private func conversion(_ tagID: String, existing: UUID? = nil) -> CategoryConversion {
        if let existing {
            return CategoryConversion(tagID: tagID, target: .existing(categoryID: existing))
        }
        return CategoryConversion(tagID: tagID, target: .new(name: tagID, color: "FF0000", icon: .sf("folder")))
    }
    
    @Test func noMappingKeepsAllTagsNoCategoryForEveryPlace() {
        let plan = MapstrImportPlan(
            places: [makePlace(id: "p1", tagIDs: ["Restaurants", "Museums"]),
                    makePlace(id: "p2", tagIDs: [])],
            tags: [makeTag("Restaurants"), makeTag("Museums")]
        )
        let resolutions = plan.resolve([])
        #expect(resolutions.count == 2)
        #expect(resolutions[0].categoryTagID == nil)
        #expect(resolutions[0].keptTagIDs == ["Restaurants", "Museums"])
        #expect(resolutions[1].categoryTagID == nil)
        #expect(resolutions[1].keptTagIDs == [])
    }

    @Test func singleConvertedTagBecomesCategoryForMatchingPlaces() {
        let plan = MapstrImportPlan(
            places: [makePlace(id: "p1", tagIDs: ["Restaurants"]),
                    makePlace(id: "p2", tagIDs: ["Museums"])],
            tags: [makeTag("Restaurants"), makeTag("Museums")]
        )
        let mapping = [conversion("Restaurants")]
        let resolutions = plan.resolve(mapping)

        let p1 = resolutions.first { $0.placeID == "p1" }!
        #expect(p1.categoryTagID == "Restaurants")
        #expect(p1.keptTagIDs == [])

        let p2 = resolutions.first { $0.placeID == "p2" }!
        #expect(p2.categoryTagID == nil)
        #expect(p2.keptTagIDs == ["Museums"])
    }

    @Test func conflictPicksHighestPriorityTagAsCategoryAndKeepsLoserAsTag() {
        let plan = MapstrImportPlan(
            places: [makePlace(id: "p1", tagIDs: ["Restaurants", "Museums"])],
            tags: [makeTag("Restaurants"), makeTag("Museums")]
        )
        // Priority: Restaurants (index 0) > Museums (index 1)
        let mapping = [conversion("Restaurants"), conversion("Museums")]
        let resolutions = plan.resolve(mapping)

        let p1 = resolutions.first { $0.placeID == "p1" }!
        #expect(p1.categoryTagID == "Restaurants")
        // The losing converted tag is still kept as a tag — "Museums" exists
        // as both a category (for other places) and a tag here.
        #expect(p1.keptTagIDs == ["Museums"])
    }

    @Test func conflictCountReflectsPlacesWithMultipleConvertedTags() {
        let plan = MapstrImportPlan(
            places: [makePlace(id: "p1", tagIDs: ["Restaurants", "Museums"]),
                    makePlace(id: "p2", tagIDs: ["Restaurants"]),
                    makePlace(id: "p3", tagIDs: ["Museums"])],
            tags: [makeTag("Restaurants"), makeTag("Museums")]
        )
        let mapping = [conversion("Restaurants"), conversion("Museums")]
        #expect(plan.conflictCount(mapping) == 1)
    }

    @Test func convertedTagThatNeverLosesIsNeverKeptAsATag() {
        let plan = MapstrImportPlan(
            places: [makePlace(id: "p1", tagIDs: ["Restaurants"]),
                    makePlace(id: "p2", tagIDs: ["Restaurants"])],
            tags: [makeTag("Restaurants")]
        )
        let mapping = [conversion("Restaurants")]
        let resolutions = plan.resolve(mapping)

        // "Restaurants" always wins wherever it appears, so it should never
        // show up as a kept tag — the tag-creation step in ImportMapstrService
        // aggregates keptTagIDs across all resolutions, so this is the
        // invariant that guarantees no tag gets created for it.
        let allKeptTagIDs = Set(resolutions.flatMap(\.keptTagIDs))
        #expect(!allKeptTagIDs.contains("Restaurants"))
    }

    @Test func resolveIgnoresConversionTargetKind() {
        let plan = MapstrImportPlan(
            places: [makePlace(id: "p1", tagIDs: ["Restaurants"])],
            tags: [makeTag("Restaurants")]
        )
        let existingID = UUID()
        let viaExisting = plan.resolve([conversion("Restaurants", existing: existingID)])
        let viaNew = plan.resolve([conversion("Restaurants")])

        // resolve() only cares about which tagIDs are converted, not whether
        // they map to an existing category or a brand new one.
        #expect(viaExisting == viaNew)
    }
}
