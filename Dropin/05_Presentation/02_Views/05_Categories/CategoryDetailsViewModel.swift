//
//  CategoryDetailsViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/25.
//

import SwiftUI

@MainActor
@Observable class CategoryDetailsViewModel {
    
    var loadingPlaces = false
    var places: [PlaceUIModel] = []
    var selectedPlaceId: UUID? = nil
    var category: CategoryUIModel
    var categoryColor: Color
    var showingRemoveAlert: Bool = false
    var showingMarkerList: Bool = false

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored var locationManager: LocationManager
    @ObservationIgnored private var coordinator: CategoryCoordinator
    @ObservationIgnored private var updateCategory: UpdateCategory
    @ObservationIgnored private var fetchCategoryPlaces: FetchCategoryPlaces
    @ObservationIgnored private var updatePlace: UpdatePlace
    
    init(_ appContainer: AppContainer,
         locationManager: LocationManager,
         coordinator: CategoryCoordinator,
         category: CategoryUIModel,
         updateCategory: UpdateCategory,
         fetchCategoryPlaces: FetchCategoryPlaces,
         updatePlace: UpdatePlace) {
        self.appContainer = appContainer
        self.locationManager = locationManager
        self.coordinator = coordinator
        self.category = category
        self.updateCategory = updateCategory
        self.fetchCategoryPlaces = fetchCategoryPlaces
        self.updatePlace = updatePlace
        self.categoryColor = category.color
    }
    
    // MARK: Actions
    func softDeleteCategory() async throws {
        category.deletedAt = Date()
        try await updateCategory(shouldUpdatePlaces: false)
        // WARN: category.places is empty here, do not rely on it
        for place in places {
            try await nullifyPlaceCategory(place)
        }
    }

    // MARK: Navigation
    func pushCategoryMapView() {
        coordinator.pushCategoryMapView(categoryId: category.id)
    }
    
    // MARK: UI Child
    func createPlaceSheetView(place: Binding<PlaceUIModel>) -> PlaceSheetView {
        return appContainer.createPlaceSheetView(place: place,
                                                 mapAction: nil,  // TODO: DRO-34 Allow "Map" action from a category/tag detail (AKA open the map centered on place)
                                                 detent: .constant(.medium))
    }
    
    // MARK: use cases
    func updateCategory(shouldUpdatePlaces: Bool = true) async throws {
        try await updateCategory(CategoryMapper.toDomain(category))
        if shouldUpdatePlaces {
            updateCachedPlaces()
        }
    }
 
    func fetchPlaces() async throws {
        loadingPlaces = true
        places = try await fetchCategoryPlaces(category.id)
            .filter { $0.isActive }
            .map { PlaceMapper.toUI($0) }
        loadingPlaces = false
    }
    
    func nullifyPlaceCategory(_ place: PlaceUIModel) async throws {
        place.category = nil
        try await updatePlace(PlaceMapper.toDomain(place))
    }
    
    // MARK: - private methods
    private func updateCachedPlaces() {
        // This is a purely UI update on PlaceUIModel array
        // so the places arrow are updated with the right category properties
        for idx in places.indices {
            places[idx].category = category.isActive ? category : nil
        }
    }
}
