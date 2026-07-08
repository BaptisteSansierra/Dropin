//
//  GroupDetailsViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/25.
//

import SwiftUI

@MainActor
@Observable class GroupDetailsViewModel {
    
    var loadingPlaces = false
    var places: [PlaceUI] = []
    var selectedPlaceId: UUID? = nil
    var group: GroupUI
    var groupColor: Color
    var showingRemoveAlert: Bool = false
    var showingMarkerList: Bool = false

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored var locationManager: LocationManager
    @ObservationIgnored private var coordinator: GroupCoordinator
    @ObservationIgnored private var updateGroup: UpdateGroup
    @ObservationIgnored private var fetchGroupPlaces: FetchGroupPlaces
    @ObservationIgnored private var updatePlace: UpdatePlace
    
    init(_ appContainer: AppContainer,
         locationManager: LocationManager,
         coordinator: GroupCoordinator,
         group: GroupUI,
         updateGroup: UpdateGroup,
         fetchGroupPlaces: FetchGroupPlaces,
         updatePlace: UpdatePlace) {
        self.appContainer = appContainer
        self.locationManager = locationManager
        self.coordinator = coordinator
        self.group = group
        self.updateGroup = updateGroup
        self.fetchGroupPlaces = fetchGroupPlaces
        self.updatePlace = updatePlace
        self.groupColor = group.color
    }
    
    // MARK: Actions
    func softDeleteGroup() async throws {
        group.deletedAt = Date()
        try await updateGroup(shouldUpdatePlaces: false)
    }

    // MARK: Navigation
    func pushGroupMapView() {
        coordinator.pushGroupMapView(groupId: group.id)
    }
    
    // MARK: UI Child
    func createPlaceSheetView(place: Binding<PlaceUI>) -> PlaceSheetView {
        return appContainer.createPlaceSheetView(place: place, detent: .constant(.medium))
    }
    
    // MARK: use cases
    func updateGroup(shouldUpdatePlaces: Bool = true) async throws {
        try await updateGroup(GroupMapper.toDomain(group))
        if shouldUpdatePlaces {
            updatePlaces()
        }
    }
 
    func fetchPlaces() async throws {
        loadingPlaces = true
        places = try await fetchGroupPlaces(group.id)
            .map({ PlaceMapper.toUI($0) })
        loadingPlaces = false
    }
    
    func updatePlace(_ place: PlaceUI) async throws {
        try await updatePlace(PlaceMapper.toDomain(place))
    }
    
    // MARK: - private methods
    private func updatePlaces() {
        for idx in places.indices {
            places[idx].group = group
        }
    }
}
