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
    
    func execute(_ group: GroupEntity) async throws {
        return try await repository.create(group)
    }
}
