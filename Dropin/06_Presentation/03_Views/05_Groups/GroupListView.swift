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
    @Binding private var showingSideMenu: Bool
        
    // MARK: - init
    init(viewModel: GroupListViewModel, showingSideMenu: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingSideMenu = showingSideMenu
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            List {
                ForEach(groups) { group in
                    if !group.databaseDeleted {
                        HStack {
                            GroupView(group: group)
                            Spacer()
                            let nPlaces = group.places.count
                            Text("group_list_view.num_places_\(nPlaces)")
                                .textStyle(.placeholder)
                        }
                        .swipeActions {
                            Button() {
                                deleteGroup(group)
                            } label: {
                                Label("common.delete", systemImage: "trash")
                            }
                            .tint(.destructive)
                        }
                        .onTapGesture {
                            viewModel.pushGroupDetailsView(groupId: group.id)
                        }
                    }
                }
            }
            .navigationTitle("common.groups")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: GroupNavigationItem.self) { navigationItem in
                resolveDestination(navigationItem: navigationItem)
            }
            .task {
                Task {
                    groups = try await viewModel.loadGroups()
                }
            }
            .toolbar {
                DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
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
    
    private func createGroupDetailsView(_ groupId: String) -> GroupDetailsView {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else {
            fatalError("couldn't find any group id '\(groupId)' in list")
        }
        return viewModel.createGroupDetailsView(group: $groups[index])
    }
    
    @ViewBuilder
    private func resolveDestination(navigationItem: GroupNavigationItem) -> some View {
        switch navigationItem {
            case .groupDetails(let groupId):
                createGroupDetailsView(groupId)
            case .undefinedDummyView:
                ZStack {
                    Color.orange
                    Text("To be implemented...")
                }
            default:
                ZStack {
                    Color.orange
                    Text("Undefined navigation item")
                }
                .onAppear {
                    assertionFailure("undefined navigation item \(navigationItem)")
                }
        }
    }
}


#if DEBUG

struct MockGroupListView: View {
    @State private var showingSideMenu: Bool = false
    var mock: MockContainer

    var body: some View {
        mock.appContainer.createGroupListView(showingSideMenu: $showingSideMenu)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
}

#Preview {
    NavigationStack {
        MockGroupListView()
    }
}

#endif
