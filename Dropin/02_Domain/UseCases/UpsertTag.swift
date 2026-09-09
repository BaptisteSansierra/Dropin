//
//  UpsertTag.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

@MainActor
struct UpsertTag {
    private let repository: TagRepository
    
    init(repository: TagRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ tag: TagEntity, shouldSave: Bool = true) async throws {
        guard !tag.name.isEmpty else {
            throw DomainError.Tag.missingName
        }
        try await repository.upsert(tag, shouldSave: shouldSave)
    }
}
