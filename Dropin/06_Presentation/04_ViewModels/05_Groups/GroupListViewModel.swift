//
//  GroupListViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/25.
//

import SwiftUI

@MainActor
@Observable class GroupListViewModel {
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var getGroups: GetGroups
    @ObservationIgnored private var deleteGroup: DeleteGroup

    init(_ appContainer: AppContainer,
         getGroups: GetGroups,
         deleteGroup: DeleteGroup) {
        self.appContainer = appContainer
        self.getGroups = getGroups
        self.deleteGroup = deleteGroup
    }
    
    // MARK: UI Child
    func createGroupDetailsView(group: Binding<GroupUI>) -> GroupDetailsView {
        return appContainer.createGroupDetailsView(group: group)
    }

    // MARK: use cases
    func loadGroups() async throws -> [GroupUI] {
        let domainItems = try await getGroups.execute()
        let items = domainItems.map { GroupMapper.toUI($0) }
        return items
    }
    
    func deleteGroup(_ group: GroupUI) async throws {
        try await deleteGroup.execute(GroupMapper.toDomain(group))
        group.databaseDeleted = true
    }
}
