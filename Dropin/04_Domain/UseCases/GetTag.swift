//
//  GetTag.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import Foundation

@MainActor
struct GetTag {
    private let repository: TagRepository
    
    init(repository: TagRepository) {
        self.repository = repository
    }
    
    func execute(id: String) async throws -> TagEntity {
        return try await repository.get(id)
    }
}
