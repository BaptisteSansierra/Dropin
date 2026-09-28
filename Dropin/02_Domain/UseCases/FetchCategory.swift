//
//  FetchCategory.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import Foundation

@MainActor
struct FetchCategory {
    private let repository: CategoryRepository
    
    init(repository: CategoryRepository) {
        self.repository = repository
    }
    
    func callAsFunction(id: UUID) async throws -> Category {
        return try await repository.fetch(id)
    }
}
