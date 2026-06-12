//
//  GroupListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI

struct GroupListView: View {
    
    // Create a specific struct so Now each row's body is its own observation context.
    private struct GroupListRow: View {
        let group: GroupUI
        var body: some View {
            GroupView(group: group, size: .regular)
        }
    }

    // MARK: - State & Bindings
    @State private var viewModel: GroupListViewModel
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
                ForEach(viewModel.groups) { group in
                    //if group.isActive {
                        groupRow(group)
                    //}
                }
            }
            .overlay {
                //if groups.filter(\.isActive).isEmpty {
                if viewModel.groups.isEmpty {
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
                        try await viewModel.loadGroups()
                    } catch {
                        // TODO: handle error
                    }
                }
            }
            .toolbar {
                DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
            }
            .alert("alert.remove_group_title",
                   isPresented: $viewModel.showingRemoveAlert,
                   presenting: viewModel.groupToRemove) { group in
                
                Button("common.cancel", role: .cancel) {
                    viewModel.groupToRemove = nil
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
            GroupListRow(group: group)
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
        viewModel.groupToRemove = group
        viewModel.showingRemoveAlert = true
    }
    
    private func deleteGroup(_ groupId: UUID) async {
        guard let index = viewModel.groups.firstIndex(where: { $0.id == groupId }) else {
            fatalError("couldn't find any group id '\(groupId)' in list")
        }
        do {
            try await viewModel.softDeleteGroup(index)
        } catch {
            // TODO: handle error
            assertionFailure("couldn't delete group")
        }
    }
    
    private func createGroupDetailsView(_ groupId: UUID) -> GroupDetailsView {
        guard let index = viewModel.groups.firstIndex(where: { $0.id == groupId }) else {
            fatalError("couldn't find any group id '\(groupId)' in list")
        }
        return viewModel.createGroupDetailsView(group: viewModel.groups[index])
    }

    private func createGroupMapView(_ groupId: UUID) -> GroupMapView {
        //guard let _ = groups.firstIndex(where: { $0.id == groupId }) else {
        //    fatalError("couldn't find any group id '\(groupId)' in list")
        //}
        return viewModel.createGroupMapView(groupId: groupId)
    }
    
    private func createPlaceEditView(_ placeRef: PlaceUIRef) -> PlaceEditView {
        return viewModel.createPlaceEditView(place: placeRef.place)
    }

    @ViewBuilder
    private func resolveDestination(navigationItem: GroupNavigationItem) -> some View {
        switch navigationItem {
            case .groupDetails(let groupId):
                createGroupDetailsView(groupId)
            case .groupMap(let groupId):
                createGroupMapView(groupId)
            case .groupPlace(let placeRef):
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
