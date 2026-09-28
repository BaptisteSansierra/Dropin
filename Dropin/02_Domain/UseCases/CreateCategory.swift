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
        guard category.name.count > 0 else {
            throw DomainError.Category.missingName
        }
        if try await repository.exists(category) {
            throw DomainError.Category.alreadyExists
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
