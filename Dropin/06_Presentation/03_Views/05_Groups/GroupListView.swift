//
//  GroupListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI
import SwiftData

struct GroupListView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: GroupListViewModel
    @State private var groups: [GroupUI] = [GroupUI]()
    @State private var showingRemoveAlert: Bool = false
    @State private var groupToRemove: GroupUI? = nil
    
    // MARK: - init
    init(viewModel: GroupListViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    if !group.databaseDeleted {
                        NavigationLink(value: GroupMapper.toDomain(group)) {
                            HStack {
                                GroupView(name: group.name, color: group.color, hasDestructiveBt: false)
                                Spacer()
                                let nPlaces = group.places.count
                                Text("group_list_view.num_places_\(nPlaces)")
                            }
                            .swipeActions {
                                Button() {
                                    deleteGroup(group)
                                } label: {
                                    Label("common.delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("common.groups")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: GroupEntity.self) { group in
                createGroupDetailsView(group)
            }
            .task {
                Task {
                    groups = try await viewModel.loadGroups()
                }
            }
            .toolbar {
                DropinToolbar.Burger()
            }
            .alert("alert.remove_group_title",
                   isPresented: $showingRemoveAlert,
                   presenting: groupToRemove) { group in
                
                Button("common.cancel", role: .cancel) {
                    groupToRemove = nil
                }
                Button("common.delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteGroup(group)
                            groupToRemove = nil
                            groups = try await viewModel.loadGroups()
                        } catch {
                            // TODO: handle error
                            assertionFailure("couldn't delete group")
                        }
                    }
                }
            } message: { group in
                if group.places.count > 0 {
                    Text("alert.remove_group_body_\(group.name)_\(group.places.count)")
                } else {
                    Text("alert.remove_group_empty_body_\(group.name)")
                }
            }
        }
    }
    
    // MARK: - Actions
    private func deleteGroup(_ group: GroupUI) {
        groupToRemove = group
        showingRemoveAlert = true
    }
    
    private func createGroupDetailsView(_ group: GroupEntity) -> GroupDetailsView {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {
            fatalError("couldn't find any group named '\(group.name)' in list")
        }
        return viewModel.createGroupDetailsView(group: $groups[index])
    }
}


#if DEBUG

struct MockGroupListView: View {
    var mock: MockContainer

    var body: some View {
        mock.appContainer.createGroupListView()
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
}

#Preview {
    NavigationStack {
        MockGroupListView()
            .environment(NavigationContext())
    }
}

#endif
