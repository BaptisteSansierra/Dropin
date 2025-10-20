//
//  GroupDetailsViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/25.
//

import SwiftUI

@MainActor
@Observable class GroupDetailsViewModel {
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var updateGroup: UpdateGroup
    @ObservationIgnored private var deleteGroup: DeleteGroup

    init(_ appContainer: AppContainer,
         updateGroup: UpdateGroup,
         deleteGroup: DeleteGroup) {
        self.appContainer = appContainer
        self.updateGroup = updateGroup
        self.deleteGroup = deleteGroup
    }
    
    // MARK: use cases
    func updateGroup(_ group: GroupUI) async throws {
        try await updateGroup.execute(GroupMapper.toDomain(group))
    }
    
    func deleteGroup(_ group: GroupUI) async throws {
        try await deleteGroup.execute(GroupMapper.toDomain(group))
        group.databaseDeleted = true
    }
}
