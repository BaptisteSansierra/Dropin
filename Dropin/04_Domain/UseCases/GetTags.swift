//
//  GetTags.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation

@MainActor
struct GetTags {
    private let repository: TagRepository
    
    init(repository: TagRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> [TagEntity] {
        return try await repository.getAll()
    }
}
