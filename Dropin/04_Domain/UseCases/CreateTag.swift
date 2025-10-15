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
        try await repository.create(tag)
    }
}
