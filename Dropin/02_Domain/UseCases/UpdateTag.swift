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
    
    func callAsFunction(_ tag: Tag) async throws {
        let tag = tag.trimmingName()
        guard !tag.name.isEmpty else {
            throw DomainError.Tag.missingName
        }
        if try await !repository.exists(tag) {
            throw DomainError.Tag.notFound
        }
        if try await repository.nameExists(tag.name, excluding: tag.id) {
            throw DomainError.Tag.nameAlreadyExists
        }
        return try await repository.update(tag)
    }
}
