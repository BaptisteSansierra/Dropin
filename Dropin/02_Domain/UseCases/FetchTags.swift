//
//  FetchTags.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation

@MainActor
struct FetchTags {
    private let repository: TagRepository
    
    init(repository: TagRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> [TagEntity] {
        return try await repository.fetch()
    }
}

