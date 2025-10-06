//
//  CreateGroup.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
struct CreateGroup {
    private let repository: GroupRepository
    
    init(repository: GroupRepository) {
        self.repository = repository
    }
    
    func execute(name: String, color: String) async throws -> GroupEntity {
        let group = GroupEntity(name: name, color: color)
        return try await repository.create(group)
    }
}
