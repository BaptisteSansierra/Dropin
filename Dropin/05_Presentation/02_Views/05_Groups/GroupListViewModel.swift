//
//  GroupListViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/25.
//

import SwiftUI

@MainActor
@Observable class GroupListViewModel {
    
    var coordinator: GroupCoordinator
    var syncStatus: SyncStatus
    var groups: [GroupUI] = []
    var showingRemoveAlert: Bool = false
    var groupToRemove: GroupUI? = nil

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchGroupsWithCount: FetchGroupsWithCount
    @ObservationIgnored private var updateGroup: UpdateGroup

    init(_ appContainer: AppContainer,
         coordinator: GroupCoordinator,
         fetchGroupsWithCount: FetchGroupsWithCount,
         updateGroup: UpdateGroup,
         syncStatus: SyncStatus) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.fetchGroupsWithCount = fetchGroupsWithCount
        self.updateGroup = updateGroup
        self.syncStatus = syncStatus
    }
    
    // MARK: Actions
    func softDeleteGroup(_ index: Int) async throws {
        // TODO: DRO-24 implement delete stategy
        groups[index].deletedAt = Date()
        try await updateGroup(groups[index])
        groups.remove(at: index)
        groupToRemove = nil
    }

    // MARK: UI Child
    func createGroupDetailsView(group: GroupUI) -> GroupDetailsView {
        return appContainer.createGroupDetailsView(group: group)
    }

    func createGroupMapView(groupId: UUID) -> GroupMapView {
        return appContainer.createGroupMapView(groupId: groupId)
    }
    
    func createPlaceEditView(place: PlaceUI) -> PlaceEditView {
        return appContainer.createPlaceEditView(place: place)
    }

    // MARK: Navigation
    func pushGroupDetailsView(groupId: UUID) {
        coordinator.pushGroupDetailsView(groupId: groupId)
    }

    // MARK: use cases
    func loadGroups() async throws {
        let result = try await fetchGroupsWithCount()
        let items = result.map { GroupMapper.toUI($0, placeCount: $1) }
        groups = items
    }

    private func updateGroup(_ group: GroupUI) async throws {
        try await updateGroup(GroupMapper.toDomain(group))
    }
}
