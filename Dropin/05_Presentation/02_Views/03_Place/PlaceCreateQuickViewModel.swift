//
//  PlaceCreateQuickViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI
import CoreLocation
import MapKit

@MainActor
@Observable class PlaceCreateQuickViewModel {
    
    // MARK: Properties
    var showingMarkerList = false
    var showingTagsSelector = false
    var showingCategorySelector = false
    var selectedCategory: CategoryRecord?
    var missingName = false
    var matchingCategory: CategoryUIModel?
    var suggestedCategoryName: String?
    var suggestedCategoryIcon: Icon?

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let createPlace: CreatePlace
    @ObservationIgnored private let getTag: FetchTag
    @ObservationIgnored private let getCategory: FetchCategory
    @ObservationIgnored private let createTag: CreateTag
    @ObservationIgnored private let createCategory: CreateCategory
    @ObservationIgnored private var coordinator: PlaceCoordinator
    @ObservationIgnored private var poiCategory: MKPointOfInterestCategory?
    @ObservationIgnored var poiColor: Color?
    @ObservationIgnored private var suggestCategoryForAppleCategory: SuggestCategoryForAppleCategory

    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         createPlace: CreatePlace,
         getTag: FetchTag,
         getCategory: FetchCategory,
         createTag: CreateTag,
         createCategory: CreateCategory,
         suggestCategoryForAppleCategory: SuggestCategoryForAppleCategory,
         poiCategory: MKPointOfInterestCategory?,
         poiColor: Color?) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.createPlace = createPlace
        self.getTag = getTag
        self.getCategory = getCategory
        self.createTag = createTag
        self.createCategory = createCategory
        self.suggestCategoryForAppleCategory = suggestCategoryForAppleCategory
        self.poiCategory = poiCategory
        self.poiColor = poiColor
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
        // The Apple-POI quick-create flow can attach a suggested category (or
        // newly-typed tags) that only exist in memory so far — make sure both
        // are actually persisted before the place links to them.
        try await ensureCategoryExists(placeEntity.category)
        try await ensureTagsExist(placeEntity.tags)
        try await createPlace(placeEntity)
    }

    private func ensureCategoryExists(_ category: Category?) async throws {
        guard let category else { return }
        do {
            _ = try await getCategory(id: category.id)
        } catch {
            try await createCategory(category)
        }
    }

    private func ensureTagsExist(_ tags: [Tag]) async throws {
        for tag in tags {
            do {
                _ = try await getTag(id: tag.id)
            } catch {
                try await createTag(tag)
            }
        }
    }
    
    // MARK: - Actions
    func fetchAddress(coords: CLLocationCoordinate2D) async throws -> String {
        return try await LocationManager.lookUpAddress(coords: coords)
    }
    
    func getSuggestedCategory() async {
        guard let poiCategory = poiCategory else { return }
        do {
            if let matching = try await suggestCategoryForAppleCategory(appleCategoryDisplayName: poiCategory.displayName) {
                // A matching category is found
                matchingCategory = CategoryMapper.toUI(matching)
            } else {
                suggestedCategoryName = poiCategory.displayName
                suggestedCategoryIcon = poiCategory.icon
            }
        } catch {
            // Just ignore it
        }
    }
}
