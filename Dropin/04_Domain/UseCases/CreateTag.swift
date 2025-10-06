//
//  CreateTag.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
struct CreateTag {
    private let repository: TagRepository
    
    init(repository: TagRepository) {
        self.repository = repository
    }
    
    func execute(name: String, color: String) async throws -> TagEntity {
        let tag = TagEntity(name: name, color: color)
        return try await repository.create(tag)
    }
}
