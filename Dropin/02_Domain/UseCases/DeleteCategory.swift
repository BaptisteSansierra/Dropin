//
//  DeleteCategory[.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/25.
//

import Foundation

// Hard delete not currently used

/*
@MainActor
struct DeleteCategory {
    private let repository: CategoryRepository
    
    init(repository: CategoryRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ category: Category) async throws {
        if try await !repository.exists(category) {
            throw DomainError.Category.notFound
        }
        return try await repository.delete(category)
    }
}
*/
