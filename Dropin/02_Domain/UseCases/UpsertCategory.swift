//
//  UpsertCategory.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

@MainActor
struct UpsertCategory {
    private let repository: CategoryRepository
    
    init(repository: CategoryRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ category: Category, shouldSave: Bool = true) async throws {
        guard !category.name.isEmpty else {
            throw DomainError.Category.missingName
        }
        try await repository.upsert(category, shouldSave: shouldSave)
    }
}
