//
//  CategoryListViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/25.
//

import SwiftUI

@MainActor
@Observable class CategoryListViewModel {
    
    var coordinator: CategoryCoordinator
    var syncStatus: SyncStatus
    var categories: [CategoryUIModel] = []
    var showingRemoveAlert: Bool = false
    var groupToRemove: CategoryUIModel? = nil

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchCategoriesWithCount: FetchCategoriesWithCount
    @ObservationIgnored private var updateCategory: UpdateCategory

    init(_ appContainer: AppContainer,
         coordinator: CategoryCoordinator,
         fetchCategoriesWithCount: FetchCategoriesWithCount,
         updateCategory: UpdateCategory,
         syncStatus: SyncStatus) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.fetchCategoriesWithCount = fetchCategoriesWithCount
        self.updateCategory = updateCategory
        self.syncStatus = syncStatus
    }
    
    // MARK: Actions
    func softDeleteCategory(_ index: Int) async throws {
        // TODO: DRO-24 implement delete stategy
        categories[index].deletedAt = Date()
        try await updateCategory(categories[index])
        categories.remove(at: index)
        groupToRemove = nil
    }

    // MARK: UI Child
    func createCategoryDetailsView(category: CategoryUIModel) -> CategoryDetailsView {
        return appContainer.createCategoryDetailsView(category: category)
    }

    func createCategoryMapView(categoryId: UUID) -> CategoryMapView {
        return appContainer.createCategoryMapView(categoryId: categoryId)
    }
    
    func createPlaceEditView(place: PlaceUIModel) -> PlaceEditView {
        return appContainer.createPlaceEditView(place: place)
    }

    // MARK: Navigation
    func pushCategoryDetailsView(categoryId: UUID) {
        coordinator.pushCategoryDetailsView(categoryId: categoryId)
    }

    // MARK: use cases
    func loadCategories() async throws {
        let result = try await fetchCategoriesWithCount()
        let items = result.map { CategoryMapper.toUI($0, placeCount: $1) }
        categories = items
    }

    private func updateCategory(_ category: CategoryUIModel) async throws {
        try await updateCategory(CategoryMapper.toDomain(category))
    }
}
