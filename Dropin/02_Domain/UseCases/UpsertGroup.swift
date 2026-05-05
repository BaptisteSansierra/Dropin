//
//  UpsertGroup.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

@MainActor
struct UpsertGroup {
    private let repository: GroupRepository
    
    init(repository: GroupRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ group: GroupEntity) async throws {
        guard !group.name.isEmpty else {
            throw DomainError.Group.missingName
        }
        try await repository.upsert(group)
    }
}
