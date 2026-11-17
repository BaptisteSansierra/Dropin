//
//  CreateCategory.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
struct CreateCategory {
    private let repository: CategoryRepository
    
    init(repository: CategoryRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ category: Category) async throws {
        let category = category.trimmingName()
        guard !category.name.isEmpty else {
            throw DomainError.Category.missingName
        }
        if try await repository.exists(category) {
            throw DomainError.Category.alreadyExists
        }
        if try await repository.nameExists(category.name, excluding: nil) {
            throw DomainError.Category.nameAlreadyExists
        }
//        if !category.icon.isValid {
//            throw DomainError.Category.undefinedMarker
//        }
        if !category.color.isValidHexaColor {
            throw DomainError.Category.invalidColor
        }
        return try await repository.create(category)
    }
}
