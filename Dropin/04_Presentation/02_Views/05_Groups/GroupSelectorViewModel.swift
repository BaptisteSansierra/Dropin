//
//  GroupSelectorViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI

@MainActor
@Observable class GroupSelectorViewModel {
    
    var groups = [GroupUI]()
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchGroups: FetchGroups
    @ObservationIgnored private var createGroup: CreateGroup
    
    init(_ appContainer: AppContainer,
         fetchGroups: FetchGroups,
         createGroup: CreateGroup) {
        self.appContainer = appContainer
        self.fetchGroups = fetchGroups
        self.createGroup = createGroup
    }
    
    // MARK: Uses cases
    func createGroup(name: String, color: String, icon: Icon) async throws -> GroupUI {
        let domainGroup = GroupEntity(name: name, color: color, icon: icon)
        try await createGroup(domainGroup)
        let group = GroupMapper.toUI(domainGroup)
        groups.append(group)
        groups = groups.defaultSorted()
        return group
    }

    func loadGroups() async throws {
        let domainGroups = try await fetchGroups()
        groups = domainGroups.map { GroupMapper.toUI($0) }
    }
}
