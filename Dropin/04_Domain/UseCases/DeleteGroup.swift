//
//  DeleteGroup[.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/25.
//

import Foundation

@MainActor
struct DeleteGroup {
    private let repository: GroupRepository
    
    init(repository: GroupRepository) {
        self.repository = repository
    }
    
    func execute(_ group: GroupEntity) async throws {
        if try await !repository.exists(group) {
            throw DomainError.Group.notFound
        }
        return try await repository.delete(group)
    }
}
