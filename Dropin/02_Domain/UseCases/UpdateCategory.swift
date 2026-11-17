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
        let category = category.trimmingName()
        guard !category.name.isEmpty else {
            throw DomainError.Category.missingName
        }
        if try await !repository.exists(category) {
            throw DomainError.Category.notFound
        }
        if try await repository.nameExists(category.name, excluding: category.id) {
            throw DomainError.Category.nameAlreadyExists
        }
        return try await repository.update(category)
    }
}
