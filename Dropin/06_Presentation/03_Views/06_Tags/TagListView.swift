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

    // MARK: - init
    init(viewModel: TagListViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                ForEach(tags) { tag in
                    if !tag.databaseDeleted {
                        NavigationLink(value: TagMapper.toDomain(tag)) {
                            HStack {
                                TagView(name: tag.name, color: tag.color)
                                Spacer()
                                let nPlaces = tag.places.count
                                Text("tag_list_view.num_places_\(nPlaces)")
                            }
                            .swipeActions {
                                Button() {
                                    deleteTag(tag)
                                } label: {
                                    Label("common.delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("common.tags")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: TagEntity.self) { tag in
                createTagDetailsView(tag)
            }
            .task{
                Task {
                    tags = try await viewModel.loadTags()
                }
            }
            .toolbar {
                DropinToolbar.Burger()
            }
            .alert("alert.remove_tag_title",
                   isPresented: $showingRemoveAlert,
                   presenting: tagToRemove) { tag in
                
                Button("common.cancel", role: .cancel) {
                    tagToRemove = nil
                }
                Button("common.delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteTag(tag)
                            tagToRemove = nil
                            tags = try await viewModel.loadTags()
                        } catch {
                            // TODO: handle error 
                            assertionFailure("couldn't delete tag")
                        }
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
    private func deleteTag(_ tag: TagUI) {
        tagToRemove = tag
        showingRemoveAlert = true
    }
    
    private func createTagDetailsView(_ tag: TagEntity) -> TagDetailsView {
        guard let index = tags.firstIndex(where: { $0.id == tag.id }) else {
            fatalError("couldn't find any tag named '\(tag.name)' in list")
        }
        return viewModel.createTagDetailsView(tag: $tags[index])
    }
}


#if DEBUG

struct MockTagListView: View {
    var mock: MockContainer

    var body: some View {
        mock.appContainer.createTagListView()
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
}

#Preview {
    NavigationStack {
        MockTagListView()
            .environment(NavigationContext())
    }
}

#endif
