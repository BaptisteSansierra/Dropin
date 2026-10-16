//
//  CategorySelectorViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI

@MainActor
@Observable class CategorySelectorViewModel {
    
    var categories = [CategoryUIModel]()
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchCategories: FetchCategories
    @ObservationIgnored private var createCategory: CreateCategory
    
    init(_ appContainer: AppContainer,
         fetchCategories: FetchCategories,
         createCategory: CreateCategory) {
        self.appContainer = appContainer
        self.fetchCategories = fetchCategories
        self.createCategory = createCategory
    }
    
    // MARK: Uses cases
    func createCategory(name: String, color: String, icon: Icon) async throws -> CategoryUIModel {
        let domainCategory = Category(name: name, color: color, icon: icon)
        try await createCategory(domainCategory)
        let category = CategoryMapper.toUI(domainCategory)
        categories.append(category)
        categories = categories.defaultSorted()
        return category
    }

    func loadCategories() async throws {
        let domainCategories = try await fetchCategories()
        categories = domainCategories
            .filter { $0.isActive }
            .map { CategoryMapper.toUI($0) }
    }
}
