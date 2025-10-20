//
//  UpdateTag.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/25.
//

import Foundation

@MainActor
struct UpdateTag {
    private let repository: TagRepository
    
    init(repository: TagRepository) {
        self.repository = repository
    }
    
    func execute(_ tag: TagEntity) async throws {
        guard tag.name.count > 0 else {
            throw DomainError.Tag.missingName
        }
        if try await !repository.exists(tag) {
            throw DomainError.Tag.notFound
        }
        return try await repository.update(tag)
    }
}
