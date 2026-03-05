//
//  TagListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI
import SwiftData

struct TagListView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: TagListViewModel
    @State private var tags: [TagUI] = [TagUI]()
    @State private var showingRemoveAlert: Bool = false
    @State private var tagToRemove: TagUI? = nil
    @Binding private var showingSideMenu: Bool
        
    // MARK: - init
    init(viewModel: TagListViewModel, showingSideMenu: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingSideMenu = showingSideMenu
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            List {
                ForEach(tags) { tag in
                    if !tag.databaseDeleted {
                        HStack {
                            TagView(name: tag.name, color: tag.color)
                            Spacer()
                            let nPlaces = tag.places.count
                            Text("tag_list_view.num_places_\(nPlaces)")
                                .textStyle(.placeholder)
                        }
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
                }
            }
            .navigationTitle("common.tags")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: TagNavigationItem.self) { navigationItem in
                resolveDestination(navigationItem: navigationItem)
            }
            .task{
                Task {
                    tags = try await viewModel.loadTags()
                }
            }
            .toolbar {
                DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
            }
            .alert("alert.remove_tag_title",
                   isPresented: $showingRemoveAlert,
                   presenting: tagToRemove) { tag in
                
                Button("common.cancel", role: .cancel) {
                    tagToRemove = nil
                }
                Button("common.delete", role: .destructive) {
                    Task {
                        await deleteTag(tag.id)
                    }
                }
            } message: { tag in
                if tag.places.count > 0 {
                    Text("alert.remove_tag_body_\(tag.name)_\(tag.places.count)")
                } else {
                    Text("alert.remove_tag_empty_body_\(tag.name)")
                }
            }
        }
    }
    
    // MARK: - Actions
    private func deleteTagCallback(_ tag: TagUI) {
        tagToRemove = tag
        showingRemoveAlert = true
    }
    
    private func deleteTag(_ tagId: UUID) async {
        guard let index = tags.firstIndex(where: { $0.id == tagId }) else {
            fatalError("couldn't find any tag id '\(tagId)' in list")
        }
        do {
            try await viewModel.deleteTag(tags[index])
            tagToRemove = nil
            tags = try await viewModel.loadTags()
        } catch {
            // TODO: handle error
            assertionFailure("couldn't delete tag")
        }
    }
    
    private func createTagDetailsView(_ tagId: UUID) -> TagDetailsView {
        guard let index = tags.firstIndex(where: { $0.id == tagId }) else {
            fatalError("couldn't find any tag id '\(tagId)' in list")
        }
        return viewModel.createTagDetailsView(tag: $tags[index])
    }
    
    @ViewBuilder
    private func resolveDestination(navigationItem: TagNavigationItem) -> some View {
        
        switch navigationItem {
            case .tagDetails(let tagId):
                createTagDetailsView(tagId)
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
