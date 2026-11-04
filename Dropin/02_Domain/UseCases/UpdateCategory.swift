//
//  UpdateCategory.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/25.
//

import Foundation

@MainActor
struct UpdateCategory {
    private let repository: CategoryRepository
    
    init(repository: CategoryRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ category: Category) async throws {
        guard category.name.count > 0 else {
            throw DomainError.Category.missingName
        }
        if try await !repository.exists(category) {
            throw DomainError.Category.notFound
        }
        return try await repository.update(category)
    }
}
