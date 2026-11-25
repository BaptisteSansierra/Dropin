//
//  UI_MapstrCategoriesViewModel.swift
//  DropinTests
//
//  Covers design_handoff_mapstr_conflicts "Done when": conflictGroups groups places by the
//  exact combination of converted tags, swap reorders the shared CategoryMapping (so every
//  group containing the swapped tags updates), and the conflict count stays consistent with
//  the pure conflictCount(plan, mapping) already covered by MapstrResolveTests.
//

import Testing
import Foundation
import CoreLocation
@testable import Dropin


@MainActor
struct UI_MapstrCategoriesViewModel {

    private func makePlace(id: String, tagIDs: [String]) -> MapstrPlace {
        MapstrPlace(id: id, name: id, coordinates: .barcelona, address: nil, icon: nil, notes: nil, tagIDs: tagIDs)
    }

    private func makeTag(_ id: String, placeCount: Int = 1) -> MapstrTag {
        MapstrTag(id: id, name: id, color: "FF0000", placeCount: placeCount)
    }

    private func makeViewModel(_ plan: MapstrImportPlan) async -> MapstrCategoriesViewModel {
        let vm = MapstrCategoriesViewModel(plan: plan, fetchCategories: FetchCategories(repository: MockCategoryRepository()))
        await vm.load()
        return vm
    }
    
    @Test func conflictGroupsGroupBySameTagSetAndOrderByPriority() async {
        // p1, p2 share {Restaurants, Museums}; p3 has only Restaurants (no conflict).
        let plan = MapstrImportPlan(
            places: [makePlace(id: "p1", tagIDs: ["Restaurants", "Museums"]),
                    makePlace(id: "p2", tagIDs: ["Museums", "Restaurants"]),
                    makePlace(id: "p3", tagIDs: ["Restaurants"])],
            tags: [makeTag("Restaurants"), makeTag("Museums")]
        )
        let vm = await makeViewModel(plan)
        vm.setChecked(true, for: "Restaurants")
        vm.setChecked(true, for: "Museums")

        let groups = vm.conflictGroups
        #expect(groups.count == 1)
        let group = groups[0]
        #expect(group.placeNames.sorted() == ["p1", "p2"])
        // Priority order follows the checked order, regardless of each place's own tagIDs order.
        #expect(group.tagIDs == ["Restaurants", "Museums"])
        #expect(group.winnerTagID == "Restaurants")
        #expect(group.loserTagIDs == ["Museums"])
    }

    @Test func swapOnTwoTagGroupReordersMappingAndUpdatesOtherGroups() async {
        // p1: {Restaurants, Museums} conflict. p2: {Museums, Shops} conflict.
        // Swapping the Restaurants/Museums group should also flip which tag wins for p2,
        // since both groups share the global priority order.
        let plan = MapstrImportPlan(
            places: [makePlace(id: "p1", tagIDs: ["Restaurants", "Museums"]),
                    makePlace(id: "p2", tagIDs: ["Museums", "Shops"])],
            tags: [makeTag("Restaurants"), makeTag("Museums"), makeTag("Shops")]
        )
        let vm = await makeViewModel(plan)
        vm.setChecked(true, for: "Restaurants")
        vm.setChecked(true, for: "Museums")
        vm.setChecked(true, for: "Shops")

        #expect(vm.mapping.map(\.tagID) == ["Restaurants", "Museums", "Shops"])

        let restaurantsMuseums = vm.conflictGroups.first { $0.tagIDs.contains("Restaurants") }!
        #expect(restaurantsMuseums.winnerTagID == "Restaurants")

        vm.swap(restaurantsMuseums)

        // Museums now outranks Restaurants globally.
        #expect(vm.mapping.map(\.tagID) == ["Museums", "Restaurants", "Shops"])

        let p1Resolution = plan.resolve(vm.mapping).first { $0.placeID == "p1" }!
        #expect(p1Resolution.categoryTagID == "Museums")

        // Museums now also outranks Shops for p2, which never had anything to do with the swap call.
        let p2Resolution = plan.resolve(vm.mapping).first { $0.placeID == "p2" }!
        #expect(p2Resolution.categoryTagID == "Museums")
    }

    @Test func setWinnerOnThreeTagGroupMovesPickedTagDirectlyAboveCurrentWinner() async {
        let plan = MapstrImportPlan(
            places: [makePlace(id: "p1", tagIDs: ["A", "B", "C"])],
            tags: [makeTag("A"), makeTag("B"), makeTag("C"), makeTag("D")]
        )
        let vm = await makeViewModel(plan)
        vm.setChecked(true, for: "A")
        vm.setChecked(true, for: "B")
        vm.setChecked(true, for: "C")
        vm.setChecked(true, for: "D")

        let group = vm.conflictGroups.first!
        #expect(group.winnerTagID == "A")

        vm.setWinner("C", in: group)

        // "C" moves directly above the previous winner "A"; "D" (uninvolved) keeps its place.
        #expect(vm.mapping.map(\.tagID) == ["C", "A", "B", "D"])
    }

    @Test func conflictPlaceCountEqualsExistingConflictCount() async {
        let plan = MapstrImportPlan(
            places: [makePlace(id: "p1", tagIDs: ["Restaurants", "Museums"]),
                    makePlace(id: "p2", tagIDs: ["Restaurants"])],
            tags: [makeTag("Restaurants"), makeTag("Museums")]
        )
        let vm = await makeViewModel(plan)
        vm.setChecked(true, for: "Restaurants")
        vm.setChecked(true, for: "Museums")

        #expect(vm.conflictingPlacesCount == 1)
    }
}
