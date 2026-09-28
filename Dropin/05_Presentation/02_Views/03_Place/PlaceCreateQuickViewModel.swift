//
//  PlaceCreateQuickViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI
import CoreLocation

@MainActor
@Observable class PlaceCreateQuickViewModel {
    
    // MARK: Properties
    var showingMarkerList = false
    var showingTagsSelector = false
    var showingCategorySelector = false
    var selectedCategory: CategoryRecord?
    var missingName = false

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let createPlace: CreatePlace
    @ObservationIgnored private var coordinator: PlaceCoordinator

    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         createPlace: CreatePlace) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.createPlace = createPlace
    }

    // MARK: Navigation
    func pushCreatePlaceFullView(place: PlaceUIModel) {
        coordinator.pushCreatePlaceFullView(coordinates: place.coordinates,
                                            address: place.address,
                                            name: place.name,
                                            marker: place.icon?.rawValue,
                                            tags: place.tags.map { $0.id },
                                            category: place.category?.id)
    }

    // MARK: UI Childs
    func createTagSelectorView(place: Binding<PlaceUIModel>) -> TagSelectorView {
        return appContainer.createTagSelectorView(place: place)
    }
    
    func createCategorySelectorView(place: Binding<PlaceUIModel>) -> CategorySelectorView {
        return appContainer.createCategorySelectorView(place: place)
    }

    // MARK: Use cases
    func save(place: PlaceUIModel) async throws {
        let placeEntity = PlaceMapper.toDomain(place)
        try await createPlace(placeEntity)
    }
    
    // MARK: - Actions
    func fetchAddress(coords: CLLocationCoordinate2D) async throws -> String {
        return try await LocationManager.lookUpAddress(coords: coords)
    }
}
