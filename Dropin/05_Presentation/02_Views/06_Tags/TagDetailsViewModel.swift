//
//  TagDetailsViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/10/25.
//

import SwiftUI

@MainActor
@Observable class TagDetailsViewModel {
    
    var tag: TagUI
    var loadingPlaces = false
    var places: [PlaceUI] = []
    var selectedPlaceId: UUID? = nil
    var tagColor: Color
    var showingRemoveAlert: Bool = false
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var coordinator: TagCoordinator
    @ObservationIgnored var locationManager: LocationManager
    @ObservationIgnored private var updateTag: UpdateTag
    @ObservationIgnored private var fetchTagPlaces: FetchTagPlaces
    @ObservationIgnored private var updatePlace: UpdatePlace
    
    init(_ appContainer: AppContainer,
         locationManager: LocationManager,
         coordinator: TagCoordinator,
         tag: TagUI,
         updateTag: UpdateTag,
         fetchTagPlaces: FetchTagPlaces,
         updatePlace: UpdatePlace) {
        self.appContainer = appContainer
        self.locationManager = locationManager
        self.coordinator = coordinator
        self.tag = tag
        self.updateTag = updateTag
        self.fetchTagPlaces = fetchTagPlaces
        self.updatePlace = updatePlace
        self.tagColor = tag.color
    }
    
    // MARK: Actions
    func softDeleteTag() async throws {
        tag.deletedAt = Date()
        try await updateTag(shouldUpdatePlaces: false)
        // WARN: tag.places is empty here, do not rely on it
        for place in places {
            guard let tagIdx = place.tags.firstIndex(where: { tag.id == $0.id }) else { continue }
            try await unlinkPlaceFromTag(place, at: tagIdx)
        }
    }
    
    // MARK: Navigation
    func pushTagMapView(tagId: UUID) {
        coordinator.pushTagMapView(tagId: tagId)
    }
    
    // MARK: UI Child
    func createPlaceSheetView(place: Binding<PlaceUI>) -> PlaceSheetView {
        return appContainer.createPlaceSheetView(place: place, detent: .constant(.medium))
    }
    
    // MARK: use cases
    func updateTag(shouldUpdatePlaces: Bool = true) async throws {
        try await updateTag(TagMapper.toDomain(tag))
        if shouldUpdatePlaces {
            updateCachedPlaces()
        }
    }
    
    func fetchPlace() async throws {
        loadingPlaces = true
        places = try await fetchTagPlaces(tag.id)
            .filter { $0.isActive }
            .map { PlaceMapper.toUI($0) }
        loadingPlaces = false
    }
    
    func unlinkPlaceFromTag(_ place: PlaceUI, at tagIdx: Int) async throws {
        place.tags.remove(at: tagIdx)
        try await updatePlace(PlaceMapper.toDomain(place))
    }
    
    // MARK: - private methods
    private func updateCachedPlaces() {
        // This is a purely UI update on PlaceUI array
        // so the places arrow are updated with the right group properties
        for idx in places.indices {
            if let tagIdx = places[idx].tags.firstIndex(where: { $0.id == tag.id }) {
                places[idx].tags[tagIdx] = tag
            }
        }
    }
}
