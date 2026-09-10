//
//  TagListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI

struct TagListView: View {
    
    // Create a specific struct so Now each row's body is its own observation context.
    // Then when tag.name changes via the detail view's mutation, only that row's body re-evaluates
    private struct TagListRow: View {
        let tag: TagUI       // TagUI is @Observable; tag is a reference
        var body: some View {
            //TagView(name: tag.name, color: tag.color)
            //            ^^^^^^^^         ^^^^^^^^^
            //       read happens inside TagListRow's body — observation is per-row

            HStack(spacing: 0) {
                let nPlaces = tag.placeCount
                let textColor: Color = nPlaces == 0 ? .textTertiary : .textPrimary
                Circle()
                    .fill(tag.color)
                    .frame(width: 8)
                    .padding(.trailing)
                Text(verbatim: tag.name)
                    .textStyle(.groupSticker, color: textColor)
                Spacer()
                Text("tag_list_view.num_places_\(nPlaces)")
                    .textStyle(.placeholder, color: textColor)
            }
        }
    }

    // MARK: - State & Bindings
    @State private var viewModel: TagListViewModel
    @Binding private var showingSideMenu: Bool
        
    // MARK: - private properties
    private var activeTags: [TagUI] {
        viewModel.tags.filter { $0.isActive }
    }

    // MARK: - init
    init(viewModel: TagListViewModel, showingSideMenu: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingSideMenu = showingSideMenu
    }
        
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(activeTags.enumerated()), id: \.offset) { idx, tag in
                            tagRow(tag)
                                .frame(height: 55)
                                .padding(.horizontal)
                            Rectangle()
                                .fill(.fieldBorder)
                                .frame(height: 1)
                                .opacity(idx == activeTags.count - 1 ? 0 : 1)
                                .padding(.leading)
                        }
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.surface1)
                            .stroke(.fieldBorder)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal)
                .scrollIndicators(.hidden)
            }
            .overlay {
                if activeTags.isEmpty {
                    placeholderView
                }
            }
            .navigationTitle("common.tags")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: TagNavigationItem.self) { navigationItem in
                resolveDestination(navigationItem: navigationItem)
            }
            .task{
                Task {
                    try await viewModel.loadTags()
                }
            }
            .toolbar {
                DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
            }
            .alert("alert.remove_tag_title",
                   isPresented: $viewModel.showingRemoveAlert,
                   presenting: viewModel.tagToRemove) { tag in
                
                Button("common.cancel", role: .cancel) {
                    viewModel.tagToRemove = nil
                }
                Button("common.delete", role: .destructive) {
                    Task {
                        await deleteTag(tag.id)
                    }
                }
            } message: { tag in
                if tag.placeCount > 0 {
                    Text("alert.remove_tag_body_\(tag.name)_\(tag.placeCount)")
                } else {
                    Text("alert.remove_tag_empty_body_\(tag.name)")
                }
            }
        }
    }
    
    private var placeholderView: some View {
        ContentUnavailableView {
            Label("placeholder.no_tags.title", systemImage: "tag")
        } description: {
            Text("placeholder.no_tags.body")
        }
    }
    
    private func tagRow(_ tag: TagUI) -> some View {
        TagListRow(tag: tag)
            .contentShape(Rectangle())
            .swipeActions {
                Button() {
                    deleteTagCallback(tag)
                } label: {
                    Label("common.delete", systemImage: "trash")
                }
                .tint(.destructive)
            }
            .onTapGesture {
                viewModel.pushTagDetailsView(tagId: tag.id)
            }
    }
    
    // MARK: - Actions
    private func deleteTagCallback(_ tag: TagUI) {
        viewModel.tagToRemove = tag
        viewModel.showingRemoveAlert = true
    }
    
    private func deleteTag(_ tagId: UUID) async {
        guard let index = viewModel.tags.firstIndex(where: { $0.id == tagId }) else {
            fatalError("couldn't find any tag id '\(tagId)' in list")
        }
        do {
            try await viewModel.softDeleteTag(index)
        } catch {
            // TODO: handle error
            assertionFailure("couldn't delete tag")
        }
    }
    
    private func createTagDetailsView(_ tagId: UUID) -> TagDetailsView {
        guard let index = viewModel.tags.firstIndex(where: { $0.id == tagId }) else {
            fatalError("couldn't find any tag id '\(tagId)' in list")
        }
        return viewModel.createTagDetailsView(tag: viewModel.tags[index])
    }
    
    private func createTagMapView(_ tagId: UUID) -> TagMapView {
        return viewModel.createTagMapView(tagId: tagId)
    }
    
    private func createPlaceEditView(_ placeRef: PlaceUIRef) -> PlaceEditView {
        return viewModel.createPlaceEditView(place: placeRef.place)
    }

    @ViewBuilder
    private func resolveDestination(navigationItem: TagNavigationItem) -> some View {
        
        switch navigationItem {
            case .tagDetails(let tagId):
                createTagDetailsView(tagId)
            case .tagMap(let tagId):
                createTagMapView(tagId)
            case .tagPlace(let placeRef):
                createPlaceEditView(placeRef)
            case .undefinedDummyView:
                ZStack {
                    Color.orange
                    Text(verbatim: "To be implemented...")
                }
            default:
                ZStack {
                    Color.orange
                    Text(verbatim: "Undefined navigation item")
                }
                .onAppear {
                    assertionFailure("undefined navigation item \(navigationItem)")
                }
        }
    }
}


#if DEBUG

struct MockTagListView: View {
    @State private var showingSideMenu: Bool = false
    var mock: MockContainer

    var body: some View {
        mock.appContainer.createTagListView(showingSideMenu: $showingSideMenu)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
}

#Preview {
    NavigationStack {
        MockTagListView()
    }
}

#endif
