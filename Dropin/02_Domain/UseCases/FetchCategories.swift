//
//  FetchCategories.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation

@MainActor
struct FetchCategories {
    private let repository: CategoryRepository
    
    init(repository: CategoryRepository) {
        self.repository = repository
    }
    
    func callAsFunction() async throws -> [Category] {
        return try await repository.fetch()
    }
}
