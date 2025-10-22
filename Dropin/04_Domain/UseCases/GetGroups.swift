//
//  GetGroups.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation

@MainActor
struct GetGroups {
    private let repository: GroupRepository
    
    init(repository: GroupRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> [GroupEntity] {
        return try await repository.getAll()
    }
}
