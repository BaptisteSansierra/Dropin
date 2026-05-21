//
//  GroupListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI

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
                    if group.isActive {
                        groupRow(group)
                    }
                }
            }
            .overlay {
                if groups.filter(\.isActive).isEmpty {
                    placeholderView
                }
            }
            .navigationTitle("common.groups")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: GroupNavigationItem.self) { navigationItem in
                resolveDestination(navigationItem: navigationItem)
            }
            .onAppear {
                Task {
                    do {
                        groups = try await viewModel.loadGroups()
                    } catch {
                        // TODO: handle error
                    }
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
                        await deleteGroup(group.id)
                    }
                }
            } message: { group in
                if group.placeCount > 0 {
                    Text("alert.remove_group_body_\(group.name)_\(group.placeCount)")
                } else {
                    Text("alert.remove_group_empty_body_\(group.name)")
                }
            }
        }
    }
    
    var placeholderView: some View {
        ContentUnavailableView {
            Label("placeholder.no_groups.title", systemImage: "folder")
        } description: {
            Text("placeholder.no_groups.body")
        }
    }

    private func groupRow(_ group: GroupUI) -> some View {
        HStack {
            GroupView(group: group, size: .regular)
            Spacer()
            let nPlaces = group.placeCount
            Text("group_list_view.num_places_\(nPlaces)")
                .textStyle(.placeholder)
        }
        .contentShape(Rectangle())
        .swipeActions {
            Button() {
                deleteGroupCallback(group)
            } label: {
                Label("common.delete", systemImage: "trash")
            }
            .tint(.destructive)
        }
        .onTapGesture {
            viewModel.pushGroupDetailsView(groupId: group.id)
        }
    }
    
    // MARK: - Actions
    private func deleteGroupCallback(_ group: GroupUI) {
        groupToRemove = group
        showingRemoveAlert = true
    }
    
    private func deleteGroup(_ groupId: UUID) async {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else {
            fatalError("couldn't find any group id '\(groupId)' in list")
        }
        do {
            try await viewModel.deleteGroup(groups[index])
            groupToRemove = nil
            groups = try await viewModel.loadGroups()
        } catch {
            // TODO: handle error
            assertionFailure("couldn't delete group")
        }
    }
    
    private func createGroupDetailsView(_ groupId: UUID) -> GroupDetailsView {
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
