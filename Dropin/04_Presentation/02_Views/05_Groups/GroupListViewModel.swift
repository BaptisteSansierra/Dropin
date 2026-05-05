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
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchGroupsWithCount: FetchGroupsWithCount
    @ObservationIgnored private var deleteGroup: DeleteGroup

    init(_ appContainer: AppContainer,
         coordinator: GroupCoordinator,
         fetchGroupsWithCount: FetchGroupsWithCount,
         deleteGroup: DeleteGroup) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.fetchGroupsWithCount = fetchGroupsWithCount
        self.deleteGroup = deleteGroup
    }
    
    // MARK: UI Child
    func createGroupDetailsView(group: Binding<GroupUI>) -> GroupDetailsView {
        return appContainer.createGroupDetailsView(group: group)
    }

    // MARK: Navigation
    func pushGroupDetailsView(groupId: UUID) {
        coordinator.pushGroupDetailsView(groupId: groupId)
    }

    // MARK: use cases
    func loadGroups() async throws -> [GroupUI] {
        let result = try await fetchGroupsWithCount()
        let items = result.map { GroupMapper.toUI($0, placeCount: $1) }
        return items
    }
    
    func deleteGroup(_ group: GroupUI) async throws {
        try await deleteGroup(GroupMapper.toDomain(group))
        if group.deletedAt == nil {
            assertionFailure("Model should have been marked deleted already for SwiftUI safety")
            group.deletedAt = Date()
        }
    }
}
