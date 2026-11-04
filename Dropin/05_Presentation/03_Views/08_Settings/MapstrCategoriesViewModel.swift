//
//  MapstrCategoriesViewModel.swift
//  Dropin
//

import SwiftUI

@MainActor
@Observable final class MapstrCategoriesViewModel {

    // MARK: - local structs
    struct TagRow: Identifiable {
        let id: String
        let name: String
        let color: String
        let placeCount: Int
        /// Non-nil when this tag matched an existing category by name, read-only, Mapstr's color is ignored.
        let existingCategoryID: UUID?
        let suggestedIcon: Icon?
        var userIcon: Icon?

        var isExistingCategory: Bool { existingCategoryID != nil }
        var effectiveIcon: Icon { userIcon ?? suggestedIcon ?? .sf("folder") }
    }

    /// One combination of converted tags shared by 2+ places (a resolve() conflict).
    /// `id` is a stable key (tagIDs sorted independently of priority) so cards keep their
    /// identity — and animate correctly — across swaps, which change `tagIDs`' order.
    struct ConflictGroup: Identifiable {
        let id: String
        /// In current priority order: index 0 is the winner (becomes the category).
        let tagIDs: [String]
        let placeNames: [String]

        var winnerTagID: String { tagIDs[0] }
        var loserTagIDs: [String] { Array(tagIDs.dropFirst()) }
    }

    // MARK: - Static methods

    /// Places with 2+ converted tags, grouped by the exact combination, sorted by place count desc.
    static func conflictGroups(plan: MapstrImportPlan, checkedIDs: [String]) -> [ConflictGroup] {
        let priorityIndex = Dictionary(uniqueKeysWithValues: checkedIDs.enumerated().map { ($1, $0) })
        var tagIDsByKey: [String: [String]] = [:]
        var placeNamesByKey: [String: [String]] = [:]

        for place in plan.places {
            let converted = place.tagIDs.filter { priorityIndex[$0] != nil }
            guard converted.count >= 2 else { continue }
            let ordered = converted.sorted { priorityIndex[$0]! < priorityIndex[$1]! }
            let key = ordered.sorted().joined(separator: "|")
            tagIDsByKey[key] = ordered
            placeNamesByKey[key, default: []].append(place.name)
        }

        return tagIDsByKey.map { key, tagIDs in
            ConflictGroup(id: key, tagIDs: tagIDs, placeNames: (placeNamesByKey[key] ?? []).sorted())
        }.sorted { lhs, rhs in
            lhs.placeNames.count != rhs.placeNames.count
                ? lhs.placeNames.count > rhs.placeNames.count
                : lhs.id < rhs.id
        }
    }
    
    // MARK: - Computed properties
    var categoryRows: [TagRow] {
        checkedIDs.compactMap { id in rows.first { $0.id == id } }
    }

    var stayingRows: [TagRow] {
        let checked = Set(checkedIDs)
        return rows.filter { !checked.contains($0.id) }
    }

    var mapping: CategoryMapping {
        checkedIDs.compactMap { id in
            guard let row = rows.first(where: { $0.id == id }) else { return nil }
            if let categoryID = row.existingCategoryID {
                return CategoryConversion(tagID: id, target: .existing(categoryID: categoryID))
            }
            return CategoryConversion(tagID: id, target: .new(name: row.name, color: row.color, icon: row.effectiveIcon))
        }
    }

    var conflictingPlacesCount: Int {
        plan.conflictCount(mapping)
    }

    var importPlaceCount: Int {
        plan.places.count
    }

    var conflictGroups: [ConflictGroup] {
        Self.conflictGroups(plan: plan, checkedIDs: checkedIDs)
    }

    // MARK: - read-only properties
    private(set) var rows: [TagRow] = []
    /// Priority order: index 0 = highest priority. Unchecking a tag removes it; checking appends it.
    private(set) var checkedIDs: [String] = []
    private(set) var dragId: String?
    private(set) var dropId: String?
    
    // MARK: - not observed properties
    @ObservationIgnored private let plan: MapstrImportPlan
    @ObservationIgnored private let fetchCategories: FetchCategories
    @ObservationIgnored private let suggestAppleCategoryForCategory = SuggestAppleCategoryForCategory()

    // MARK: - init
    init(plan: MapstrImportPlan, fetchCategories: FetchCategories) {
        self.plan = plan
        self.fetchCategories = fetchCategories
    }

    // MARK: - public methods
    func load() async {
        let existingCategories = (try? await fetchCategories()) ?? []
        let activeCategories = existingCategories.filter { $0.isActive }
        rows = plan.tags.map { tag in
            let matchedCategory = activeCategories.first { $0.name.lemmaNormalized == tag.name.lemmaNormalized }
            let suggestedIcon = matchedCategory?.icon ?? suggestAppleCategoryForCategory(tag.name)?.icon
            return TagRow(id: tag.id,
                         name: tag.name,
                         color: tag.color,
                         placeCount: tag.placeCount,
                         existingCategoryID: matchedCategory?.id,
                         suggestedIcon: suggestedIcon,
                         userIcon: nil)
        }
    }

    func isChecked(_ id: String) -> Bool {
        checkedIDs.contains(id)
    }

    func setChecked(_ checked: Bool, for id: String) {
        if checked {
            guard !checkedIDs.contains(id) else { return }
            checkedIDs.append(id)
        } else {
            checkedIDs.removeAll { $0 == id }
        }
    }

    func setUserIcon(_ icon: Icon, for id: String) {
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        rows[index].userIcon = icon
    }

    func icon(for id: String) -> Icon? {
        rows.first { $0.id == id }?.effectiveIcon
    }

    func row(for id: String) -> TagRow? {
        rows.first { $0.id == id }
    }

    // MARK: conflicts
    /// 2-tag group: flips winner and loser.
    func swap(_ group: ConflictGroup) {
        guard group.tagIDs.count == 2 else { return }
        setWinner(group.tagIDs[1], in: group)
    }

    /// 3+ tag group: the "Set category" menu moves the picked tag directly above the current winner.
    func setWinner(_ tagID: String, in group: ConflictGroup) {
        guard tagID != group.winnerTagID else { return }
        withAnimation(.snappy) {
            moveAbove(tagID, winnerID: group.winnerTagID)
        }
    }

    private func moveAbove(_ tagID: String, winnerID: String) {
        guard let tagIndex = checkedIDs.firstIndex(of: tagID) else { return }
        checkedIDs.remove(at: tagIndex)
        let insertIndex = checkedIDs.firstIndex(of: winnerID) ?? checkedIDs.count
        checkedIDs.insert(tagID, at: insertIndex)
    }

    // MARK: drag & drop
    func dragStarted(_ id: String) {
        dragId = id
    }

    func dragEntered(_ id: String) {
        dropId = id
    }
    
    func dropped() -> Bool {
        guard let dragId, let dropId,
              dragId != dropId,
              let from = checkedIDs.firstIndex(of: dragId),
              let to = checkedIDs.firstIndex(of: dropId) else {
            self.dragId = nil
            self.dropId = nil
            return false
        }
        withAnimation {
            move(fromOffsets: IndexSet(integer: from),
                 toOffset: to > from ? to + 1 : to)
        }
        self.dragId = nil
        self.dropId = nil
        return true
    }

    // MARK: - private methods
    private func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        checkedIDs.move(fromOffsets: source, toOffset: destination)
    }
}
