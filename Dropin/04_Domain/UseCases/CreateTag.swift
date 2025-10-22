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
    
    func execute(_ tag: TagEntity) async throws {
        guard tag.name.count > 0 else {
            throw DomainError.Tag.missingName
        }
        if try await repository.exists(tag) {
            throw DomainError.Place.alreadyExists
        }
        try await repository.create(tag)
    }
}
