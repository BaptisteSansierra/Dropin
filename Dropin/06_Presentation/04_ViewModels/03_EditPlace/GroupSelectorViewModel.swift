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
    @ObservationIgnored private var getGroups: GetGroups
    @ObservationIgnored private var createGroup: CreateGroup
    
    init(_ appContainer: AppContainer,
         getGroups: GetGroups,
         createGroup: CreateGroup) {
        self.appContainer = appContainer
        self.getGroups = getGroups
        self.createGroup = createGroup
    }
    
    // MARK: Uses cases
    func createGroup(name: String, color: String) async throws -> GroupUI {
        let domainGroup = GroupEntity(name: name, color: color)
        try await createGroup.execute(domainGroup)
        let group = GroupMapper.toUI(domainGroup)
        groups.append(group)
        groups = groups.defaultSorted()
        return group
    }

    func loadGroups() async throws {
        let domainGroups = try await getGroups.execute()
        groups = domainGroups.map { GroupMapper.toUI($0) }
    }
}
