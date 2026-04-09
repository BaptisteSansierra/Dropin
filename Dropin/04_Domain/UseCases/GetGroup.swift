//
//  GetGroup.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import Foundation

@MainActor
struct GetGroup {
    private let repository: GroupRepository
    
    init(repository: GroupRepository) {
        self.repository = repository
    }
    
    func execute(id: UUID) async throws -> GroupEntity {
        return try await repository.fetch(id)
    }
}
