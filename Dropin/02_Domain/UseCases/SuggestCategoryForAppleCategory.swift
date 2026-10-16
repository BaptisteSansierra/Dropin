//
//  SuggestCategoryForAppleCategory.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/10/26.
//

import Foundation

/// Suggests an existing local Category whose name plausibly matches an Apple POI category's (already-localized) display name
/// e.g. "Restaurant" / "Restaurants" /"restaurant" should all match a POI category displaying as "Restaurant"
///
/// Matching uses `String.lemmaNormalized` the reverse direction lives in SuggestAppleCategoryForCategory
@MainActor
struct SuggestCategoryForAppleCategory {
    private let repository: CategoryRepository

    init(repository: CategoryRepository) {
        self.repository = repository
    }

    func callAsFunction(appleCategoryDisplayName: String) async throws -> Category? {
        let target = appleCategoryDisplayName.lemmaNormalized
        guard !target.isEmpty else { return nil }
        let categories = try await repository.fetch()
        return categories.first { $0.name.lemmaNormalized == target }
    }
}
