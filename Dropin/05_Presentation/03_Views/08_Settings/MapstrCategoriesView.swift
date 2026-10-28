//
//  MapstrCategoriesView.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/26.
//

import SwiftUI

struct MapstrCategoriesView: View {

    // MARK: - States & Bindings
    @State private var viewModel: MapstrCategoriesViewModel
    @State private var editingIcon: EditingIcon?
    @State private var showConflicts = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - private properties
    private let onImport: (CategoryMapping) -> Void
    private struct EditingIcon: Identifiable { let id: String }

    // MARK: - init
    init(viewModel: MapstrCategoriesViewModel, onImport: @escaping (CategoryMapping) -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onImport = onImport
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                #if false
                List {
                    Section {
                        Text("mapstr_categories.intro")
                            .textStyle(.body, color: .textSecondary)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    categoriesSection
                    tagsSection
                }
//                .listStyle(.plain)
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
                
                #else
                
                ScrollView {
                    Text("mapstr_categories.intro")
                        .textStyle(.subheadline, color: .textSecondary)
                    
                    categoriesSection
                    
                    tagsSection

                }
                .padding(.horizontal)
                .padding(.top)

                #endif
                

                bottomBar
            }
            .background(.backgroundPrimary)
            .navigationTitle("mapstr_categories.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                        .tint(.dropinPrimary)
                }
            }
            .fullScreenCover(item: $editingIcon) { item in
                MarkerListView(selected: Binding(
                    get: { viewModel.icon(for: item.id) ?? .sf("folder") },
                    set: { viewModel.setUserIcon($0, for: item.id) }
                ))
            }
            .navigationDestination(isPresented: $showConflicts) {
                MapstrConflictsView(conflictPlaceCount: viewModel.conflictingPlacesCount,
                                    getConflictGroups: { viewModel.conflictGroups },
                                    getRow: viewModel.row,
                                    swap: viewModel.swap,
                                    setWinner: viewModel.setWinner)
            }
        }
        .task {
            await viewModel.load()
            #if false
            // Testing purpose
            viewModel.setChecked(true, for: viewModel.stayingRows[0].id)
            viewModel.setChecked(true, for: viewModel.stayingRows[1].id)
            #endif
        }
    }

    // MARK: - Subviews : Become categories
    @ViewBuilder
    private var categoriesSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Text("mapstr_categories.section.categories")
                    .textStyle(.formSectionTitle)
                    .textCase(.uppercase)
                Spacer()
                if !viewModel.categoryRows.isEmpty {
                    Text("mapstr_categories.section.categories.hint")
                        .textStyle(.caption, color: .textTertiary)
                }
            }
            .padding(.bottom, 10)
            if viewModel.categoryRows.isEmpty {
                emptyCategoriesRow
                    .listRowSeparator(.hidden)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.categoryRows.enumerated()), id: \.element.id) { idx, row in
                        VStack(spacing: 0) {
                            categoryRow(row, priority: idx + 1)
                                .frame(height: 55)
                            if idx < viewModel.categoryRows.count - 1 {
                                Rectangle()
                                    .fill(.fieldBorder)
                                    .frame(height: 1)
                                    .padding(.trailing, -15)
                                    .padding(.leading, 31)
                            }
                        }
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                        .onDrag {
                            viewModel.dragStarted(row.id)
                            return NSItemProvider(object: row.id as NSString)
                        }
                        .onDrop(of: [.text],
                                isTargeted: Binding(
                                    get: { false },
                                    set: { if $0 { viewModel.dragEntered(row.id) } }
                                ),
                                perform: { _ in
                                    return viewModel.dropped()
                                })
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.surface1)
                        .stroke(.fieldBorder)
                }
            }
        }
        .padding(.top)
    }
    
    private var emptyCategoriesRow: some View {
        Text("mapstr_categories.empty")
            .textStyle(.caption, color: .textTertiary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding()
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(.textTertiary.opacity(0.4))
            }
    }

    private func categoryRow(_ row: MapstrCategoriesViewModel.TagRow, priority: Int) -> some View {
        HStack(spacing: 0) {
            // Checkbox
            Button {
                #if true
                viewModel.setChecked(false, for: row.id)
                #else
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    viewModel.setChecked(false, for: row.id)
                }
                #endif
                
            } label: {
                Circle()
                    .fill(.dropinPrimary)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 10)
            // Priority
            Text(priority, format: .number)
                .textStyle(.caption, color: .textTertiary)
                .fontWeight(.bold)
                .frame(width: 16, alignment: .center)
                .padding(.trailing, 8)
            // Icon
            categoryIconTile(row)
                .padding(.trailing, 12)
            // Category name
            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .textStyle(.bodySemibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                subtitle(for: row)
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 10)
            // Place count
            Text(row.placeCount, format: .number)
                .textStyle(.caption, color: .textTertiary)
                .padding(.trailing, 10)
            // Drag indicator
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.textTertiary)
                    .frame(width: 15, height: 1)
                    .padding(.bottom, 3)
                Rectangle()
                    .fill(.textTertiary)
                    .frame(width: 15, height: 1)
                    .padding(.bottom, 3)
                Rectangle()
                    .fill(.textTertiary)
                    .frame(width: 15, height: 1)
            }
        }
    }

    @ViewBuilder
    private func categoryIconTile(_ row: MapstrCategoriesViewModel.TagRow) -> some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(rgba: row.color))
                .frame(width: 34, height: 34)
                .overlay {
                    IconView(icon: row.effectiveIcon)
                        .size(16)
                        .foregroundStyle(.white)
                }
            if !row.isExistingCategory {
                Circle()
                    .fill(.surface1)
                    .frame(width: 16, height: 16)
                    .overlay {
                        Circle()
                            .strokeBorder(.backgroundPrimary, lineWidth: 1.5)
                    }
                    .overlay {
                        Image(systemName: "pencil")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.dropinPrimary)
                    }
                    .offset(x: 4, y: 4)
            }
        }
        .contentShape(Rectangle())
        .frame(width: 44, height: 44, alignment: .center)
        .onTapGesture {
            guard !row.isExistingCategory else { return }
            editingIcon = EditingIcon(id: row.id)
        }
    }

    @ViewBuilder
    private func subtitle(for row: MapstrCategoriesViewModel.TagRow) -> some View {
        if row.isExistingCategory {
            HStack(spacing: 3) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                Text("mapstr_categories.row.existing_\(row.name)")
            }
            .textStyle(.caption, color: .textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if row.suggestedIcon != nil {
            Text("mapstr_categories.row.new_suggested")
                .textStyle(.caption, color: .textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("mapstr_categories.row.new_default")
                .textStyle(.caption, color: .textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Subviews : Stay tags
    private var tagsSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Text("mapstr_categories.section.tags")
                    .textStyle(.formSectionTitle)
                    .textCase(.uppercase)
                Spacer()
                Text("mapstr_categories.section.tags_\(viewModel.stayingRows.count)")
                    .textStyle(.caption, color: .textTertiary)
            }
            .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.stayingRows.enumerated()), id: \.offset) { idx, row in
                    stayingTagRow(row)
                    if idx < viewModel.stayingRows.count - 1 {
                        Rectangle()
                            .fill(.fieldBorder)
                            .frame(height: 1)
                            .padding(.trailing, -15)
                            .padding(.leading, 31)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.surface1)
                    .stroke(.fieldBorder)
            }
        }
        .padding(.top)
    }

    private func stayingTagRow(_ row: MapstrCategoriesViewModel.TagRow) -> some View {
        HStack(spacing: 0) {
            Button {
                viewModel.setChecked(true, for: row.id)
            } label: {
                Circle()
                    .strokeBorder(.textTertiary.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 40)
            .padding(.leading, 4)

            Image(systemName: "tag")
                .foregroundStyle(Color(rgba: row.color))
                .padding(.trailing, 10)
            Text(row.name)
                .textStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.placeCount, format: .number)
                .textStyle(.caption, color: .textTertiary)
                .padding(.trailing)
        }
        .frame(height: 40)
        .padding(.vertical, 6)
    }

    // MARK: - Subviews : bottom bar
    private var bottomBar: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(.fieldBorder)
                .frame(height: 1)

            if viewModel.conflictingPlacesCount > 0 {
                Button {
                    showConflicts = true
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.textSecondary)
                        (Text(conflictsAttributedString)
                            .font(TextStyle.caption.font)
                            .foregroundColor(.textSecondary)
                         + Text(verbatim: " ")
                         + Text("mapstr_categories.conflicts.review")
                            .font(TextStyle.link.font)
                            .foregroundColor(TextStyle.link.color))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.surface1)
                    }
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }

            MainButton(text: "mapstr_categories.import_\(viewModel.importPlaceCount)") {
                onImport(viewModel.mapping)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(.backgroundPrimary)
    }

    /// The catalog's plural resolution leaves the `**...**` markers literal when read through
    /// a plain `Text(LocalizedStringKey)` interpolation, so the bold has to be parsed explicitly.
    private var conflictsAttributedString: AttributedString {
        let resolved = String(localized: "mapstr_categories.conflicts_\(viewModel.conflictingPlacesCount)")
        return (try? AttributedString(markdown: resolved)) ?? AttributedString(resolved)
    }
}


#if DEBUG

struct MockMapstrCategoriesView: View {

    @State var mock = MockContainer()
    @State var showingSideMenu = false
    @State private var appSettings: AppSettings
    
    private var importPlan: MapstrImportPlan

    var body: some View {
        mock.appContainer.createMapstrCategoriesView(plan: importPlan) { mapin in
            print("PROCESS...")
        }
    }
    
    init() {
        appSettings = AppSettings()
        /*
        let t1 = MapstrTag(id: UUID().uuidString,
                           name: "Restaurant",
                           color: "#EF3325",
                           placeCount: 3)  // p1, p2, p3
        let t2 = MapstrTag(id: UUID().uuidString,
                           name: "Museum",
                           color: "#AB12E4",
                           placeCount: 2)  // p3, p4
        let t3 = MapstrTag(id: UUID().uuidString,
                          name: "To Try",
                           color: String.randomColor(),
                          placeCount: 3)  // p1, p2, p3
        let t4 = MapstrTag(id: UUID().uuidString,
                          name: "Vegan",
                           color: "#142399",
                          placeCount: 2)  // p1, p3

        let p1 = MapstrPlace(id: UUID().uuidString,
                             name: "Chez jojo",
                             coordinates: .barcelona.offset(x: 0.1),
                             address: "none",
                             icon: nil,
                             notes: "no note",
                             tagIDs: [t1.id, t3.id, t4.id])
        let p2 = MapstrPlace(id: UUID().uuidString,
                             name: "Chez pipo",
                             coordinates: .barcelona.offset(x: 0.2),
                             address: "none",
                             icon: nil,
                             notes: "no note",
                             tagIDs: [t1.id, t3.id])
        let p3 = MapstrPlace(id: UUID().uuidString,
                             name: "Chez banjo museum",
                             coordinates: .barcelona.offset(y: 0.1),
                             address: "none",
                             icon: nil,
                             notes: "no note",
                             tagIDs: [t1.id, t2.id, t3.id, t4.id])
        let p4 = MapstrPlace(id: UUID().uuidString,
                             name: "Wood museum",
                             coordinates: .barcelona.offset(y: 0.2),
                             address: "none",
                             icon: nil,
                             notes: "no note",
                             tagIDs: [t2.id])
        importPlan = MapstrImportPlan(places: [p1, p2, p3, p4],
                                      tags: [t1, t2, t3, t4])
         */
        
        let t1 = MapstrTag(id: UUID().uuidString,
                           name: "Restaurant",
                           color: "#EF3325",
                           placeCount: 3)  // p1, p2
        let t2 = MapstrTag(id: UUID().uuidString,
                           name: "Museum",
                           color: "#AB12E4",
                           placeCount: 3)  // p1, p2
        let t3 = MapstrTag(id: UUID().uuidString,
                          name: "To Try",
                           color: String.randomColor(),
                          placeCount: 3)  // p1, p2
        let p1 = MapstrPlace(id: UUID().uuidString,
                             name: "Chez jojo",
                             coordinates: .barcelona.offset(x: 0.1),
                             address: "none",
                             icon: nil,
                             notes: "no note",
                             tagIDs: [t1.id, t2.id, t3.id])
        let p2 = MapstrPlace(id: UUID().uuidString,
                             name: "Chez pipo",
                             coordinates: .barcelona.offset(x: 0.2),
                             address: "none",
                             icon: nil,
                             notes: "no note",
                             tagIDs: [t1.id, t2.id, t3.id])
        importPlan = MapstrImportPlan(places: [p1, p2],
                                      tags: [t1, t2, t3])

    }
}

#Preview {
    MockMapstrCategoriesView()
        .environment(AppSettings())
}

#endif
