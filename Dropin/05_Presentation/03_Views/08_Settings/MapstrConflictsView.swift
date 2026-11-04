//
//  MapstrConflictsView.swift
//  Dropin
//
//  Pushed from the conflict note on MapstrCategoriesView ("Review ›"). Reuses the same
//  MapstrCategoriesViewModel — reads and mutates its CategoryMapping — so swapping here is
//  immediately reflected back on MapstrCategoriesView.
//

import SwiftUI

struct MapstrConflictsView: View {

    typealias ConflictGroup = MapstrCategoriesViewModel.ConflictGroup
    typealias TagRow = MapstrCategoriesViewModel.TagRow

    private let conflictPlaceCount: Int
    private let getConflictGroups: () -> [ConflictGroup]
    private let getRow: (String) -> TagRow?
    private let swap: (ConflictGroup) -> Void
    private let setWinner: (String, ConflictGroup) -> Void

    init(conflictPlaceCount: Int,
         getConflictGroups: @escaping () -> [ConflictGroup],
         getRow: @escaping (String) -> TagRow?,
         swap: @escaping (ConflictGroup) -> Void,
         setWinner: @escaping (String, ConflictGroup) -> Void) {
        self.conflictPlaceCount = conflictPlaceCount
        self.getConflictGroups = getConflictGroups
        self.getRow = getRow
        self.swap = swap
        self.setWinner = setWinner
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("mapstr_conflicts.intro")
                    .textStyle(.body, color: .textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                summaryHeader

                if getConflictGroups().isEmpty {
                    Text("mapstr_conflicts.empty")
                        .textStyle(.body, color: .textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    ForEach(getConflictGroups()) { group in
                        conflictCard(group)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
        }
        .background(.backgroundPrimary)
        .navigationTitle("mapstr_conflicts.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews
    private var summaryHeader: some View {
        HStack(spacing: 4) {
            Text("mapstr_conflicts.places_\(conflictPlaceCount)")
            Text(verbatim: "·")
            Text("mapstr_conflicts.combinations_\(getConflictGroups().count)")
        }
        .textStyle(.formSectionTitle)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func conflictCard(_ group: MapstrCategoriesViewModel.ConflictGroup) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 0) {
                Text(combinationName(group))
                    .textStyle(.bodySemibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 15)
                Text("mapstr_conflicts.places_\(group.placeNames.count)")
                    .textStyle(.caption, color: .textTertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Rectangle()
                .fill(.hairline)
                .frame(height: 1)

            // Places category row
            cardLine(label: "mapstr_conflicts.category") {
                categoryTile(group.winnerTagID)
                    .padding(.trailing, 10)
                Text(tagName(group.winnerTagID))
                    .textStyle(.bodySemibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // Places tags row
            cardLine(label: "mapstr_conflicts.stays_tag") {
                Image(systemName: "tag")
                    .foregroundStyle(.textTertiary)
                    .frame(width: 26, height: 26)
                    .padding(.trailing, 10)
                Text(group.loserTagIDs.map(tagName).joined(separator: ", "))
                    .textStyle(.body, color: .textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            HStack {
                swapControl(group)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            Rectangle()
                .fill(.hairline)
                .frame(height: 1)

            placeChips(group)
                .padding(.horizontal)
                .padding(.top, 11)
                .padding(.bottom, 13)
        }
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.surface1)
                .stroke(.backgroundTertiary)
        }
    }

    private func cardLine<Content: View>(label: LocalizedStringKey,
                                         @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .textStyle(.caption, color: .textTertiary)
                .minimumScaleFactor(0.33)
                .frame(width: 76, alignment: .leading)
                .padding(.trailing, 5)
            content()
        }
    }

    private func categoryTile(_ tagID: String) -> some View {
        let row = getRow(tagID)
        return RoundedRectangle(cornerRadius: 8)
            .fill(Color(rgba: row?.color ?? "888888"))
            .frame(width: 26, height: 26)
            .overlay {
                IconView(icon: row?.effectiveIcon ?? .sf("folder"))
                    .size(13)
                    .foregroundStyle(.white)
            }
    }

    @ViewBuilder
    private func swapControl(_ group: MapstrCategoriesViewModel.ConflictGroup) -> some View {
        if group.tagIDs.count == 2 {
            Button {
                swap(group)
            } label: {
                swapCapsuleLabel {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("mapstr_conflicts.swap")
                }
            }
            .buttonStyle(.plain)
        } else {
            Menu {
                ForEach(group.loserTagIDs, id: \.self) { tagID in
                    Button(tagName(tagID)) {
                        setWinner(tagID, group)
                    }
                }
            } label: {
                swapCapsuleLabel {
                    Text("mapstr_conflicts.set_category")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                }
            }
        }
    }

    private func swapCapsuleLabel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 6) {
            content()
        }
        .textStyle(.secondaryButton)
        .padding(.horizontal, 13)
        .frame(height: 36)
        .background(.backgroundPrimary, in: Capsule())
    }

    @ViewBuilder
    private func placeChips(_ group: MapstrCategoriesViewModel.ConflictGroup) -> some View {
        FlowLayout(alignment: .leading, spacingV: 6, spacingH: 6) {
            ForEach(group.placeNames.prefix(3), id: \.self) { name in
                Text(name)
                    .textStyle(.caption, color: .textSecondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(.backgroundPrimary, in: RoundedRectangle(cornerRadius: 8))
            }
            if group.placeNames.count > 3 {
                Text("mapstr_conflicts.more_\(group.placeNames.count - 3)")
                    .textStyle(.caption, color: .textTertiary)
                    .padding(.vertical, 4)
            }
        }
    }

    // MARK: - private helpers
    private func tagName(_ tagID: String) -> String {
        getRow(tagID)?.name ?? tagID
    }

    private func combinationName(_ group: MapstrCategoriesViewModel.ConflictGroup) -> String {
        group.tagIDs.map(tagName).joined(separator: " + ")
    }
}

#if DEBUG

struct MockMapstrConflictsView: View {

    typealias ConflictGroup = MapstrCategoriesViewModel.ConflictGroup
    typealias TagRow = MapstrCategoriesViewModel.TagRow

    @State var mock = MockContainer()
    @State var showingSideMenu = false
    
    private var importPlan: MapstrImportPlan
    private(set) var rows: [TagRow] = []
    private var conflictPlaceCount: Int = 0
    @State private var checkedIDs: [String] = ["T1", "T2", "T3"]

    var body: some View {
        MapstrConflictsView(conflictPlaceCount: conflictPlaceCount,
                            getConflictGroups: getConflictGroups,
                            getRow: getRow,
                            swap: swap,
                            setWinner: setWinner)
    }
    
    private func getConflictGroups() -> [ConflictGroup] {
        MapstrCategoriesViewModel.conflictGroups(plan: importPlan, checkedIDs: checkedIDs)
    }
    private func getRow(id: String) -> TagRow? {
        rows.first { $0.id == id }
    }
    private func swap(_ group: ConflictGroup) -> Void {
        guard group.tagIDs.count == 2 else { return }
        setWinner(group.tagIDs[1], in: group)
    }
    private func setWinner(_ tagID: String, in group: ConflictGroup) {
        guard tagID != group.winnerTagID else { return }
        withAnimation(.snappy) {
            guard let tagIndex = checkedIDs.firstIndex(of: tagID) else { return }
            checkedIDs.remove(at: tagIndex)
            let insertIndex = checkedIDs.firstIndex(of: group.winnerTagID) ?? checkedIDs.count
            checkedIDs.insert(tagID, at: insertIndex)
        }
    }
    
    init() {

        let t1 = MapstrTag(id: "T1",
                           name: "Restaurant",
                           color: "#EF3325",
                           placeCount: 9)
        let t2 = MapstrTag(id: "T2",
                           name: "Museum",
                           color: "#AB12E4",
                           placeCount: 9)
        let t3 = MapstrTag(id: "T3",
                           name: "To Try",
                           color: String.randomColor(),
                           placeCount: 9)
        let t4 = MapstrTag(id: "T4",
                           name: "Dogs friendly",
                           color: String.randomColor(),
                           placeCount: 9)
        let placesN = ["Pipo", "Jojo", "Paul",
                       "François", "Frederic", "Georges",
                       "Dudu", "Dédé", "Momo"]
        var places = [MapstrPlace]()
        for name in placesN {
            let p = MapstrPlace(id: name,
                                name: "Chez \(name)",
                                coordinates: .barcelona,
                                address: "none",
                                icon: nil,
                                notes: "no note",
                                tagIDs: [t1.id, t2.id, t3.id, t4.id])
            places.append(p)
        }
        conflictPlaceCount += places.count

        
        let placesN2 = ["Jack", "John", "Davis"]
        var places2 = [MapstrPlace]()
        for name in placesN2 {
            let p = MapstrPlace(id: name,
                                name: "\(name)'s",
                                coordinates: .barcelona,
                                address: "none",
                                icon: nil,
                                notes: "no note",
                                tagIDs: [t1.id, t2.id])
            places2.append(p)
        }
        conflictPlaceCount += places2.count



        importPlan = MapstrImportPlan(places: [places, places2].flatMap({ $0 }),
                                      tags: [t1, t2, t3, t4])

        rows = importPlan.tags.map { tag in
            return TagRow(id: tag.id,
                         name: tag.name,
                         color: tag.color,
                         placeCount: tag.placeCount,
                         existingCategoryID: nil,
                         suggestedIcon: nil,
                         userIcon: nil)
        }
    }
}

#Preview {
    MockMapstrConflictsView()
}

#endif
