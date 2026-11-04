//
//  FetchCategoriesWithCount.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/4/26.
//

import Foundation

@MainActor
struct FetchCategoriesWithCount {
    private let repository: CategoryRepository
    
    init(repository: CategoryRepository) {
        self.repository = repository
    }
    
    func callAsFunction() async throws -> [(Category, Int)] {
        return try await repository.fetchWithPlaceCount()
    }
}

