//
//  DeleteTag.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/25.
//

import Foundation

@MainActor
struct DeleteTag {
    private let repository: TagRepository
    
    init(repository: TagRepository) {
        self.repository = repository
    }
    
    func execute(_ tag: TagEntity) async throws {
        if try await !repository.exists(tag) {
            throw DomainError.Tag.notFound
        }
        return try await repository.delete(tag)
    }
}
