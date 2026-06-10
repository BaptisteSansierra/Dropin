//
//  MainViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation
import SwiftUI
import CoreLocation

@MainActor
@Observable class MainViewModel {
    
    // MARK: - Observed properties
    var coordinator: MainCoordinator
    var places: [PlaceUI] = [PlaceUI]()
    /*private(set)*/ var mapReloadGen: Int = 0    // bumps after each significant reload

    var syncStatus: SyncStatus

    /// Places filtered with `currentFilter`
    var filteredPlaces: [PlaceUI] {
        guard let filter = currentFilter else { return places }
        return filter.apply(places)
    }

    /// Places filtered with `currentFilter` ans sorted with `sortPolicy`
    var sortedPlaces: [PlaceUI] {
        sortPolicy.apply(filteredPlaces, userPosition: locationManager.lastKnownLocation)
    }
    
    /// Filter applied on map & list
    var currentFilter: PlaceFilter?

    /// Sorting policy applied on list
    var sortPolicy: PlaceSortPolicy = .distance

    /// show/hide the filter view
    var showingFilter: Bool = false
    
    /// show/hide the 'create new place' menu
    var showingCreatePlaceMenu: Bool = false

    /// Should be set to true when showing sidebar / presenting add place menu / ...
    var isPresenting: Bool = false

    /// Current selected place id
    var selectedPlaceId: UUID?

    /// Current place detail sheet detent
    var detailSheetDetent: PresentationDetent = .medium

    var navBarHeight: CGFloat = 0
    var selectedTab: Int = 0

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var locationManager: LocationManager
    @ObservationIgnored private var fetchPlaces: FetchPlaces

    // MARK: init
    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         locationManager: LocationManager,
         fetchPlaces: FetchPlaces,
         syncStatus: SyncStatus) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
        self.fetchPlaces = fetchPlaces
        self.syncStatus = syncStatus
    }

    // MARK: UI Child
    func createPlacesMapView(navBarHeight: CGFloat) -> PlacesMapView {
        let bindingSelectedPlaceId = Binding<UUID?> {
            self.selectedPlaceId
        } set: { newValue in
            self.selectedPlaceId = newValue
        }
        let bindingShowingCreatePlaceMenu = Binding<Bool>(
            get: {
                return self.showingCreatePlaceMenu
            }, set: { value in
                self.showingCreatePlaceMenu = value
            })
        let bindingIsPresenting = Binding<Bool>(
            get: {
                return self.isPresenting
            }, set: { value in
                self.isPresenting = value
            })
        return appContainer.createPlacesMapView(places: filteredPlaces,
                                                selectedPlaceId: bindingSelectedPlaceId,
                                                isParentPresenting: bindingIsPresenting,
                                                showingCreatePlaceMenu: bindingShowingCreatePlaceMenu,
                                                mapReloadGen: mapReloadGen,
                                                navBarHeight: navBarHeight)
    }
    
    func createPlacesListView() -> PlacesListView {
        let bindingSelectedPlaceId = Binding<UUID?> {
            self.selectedPlaceId
        } set: { newValue in
            self.selectedPlaceId = newValue
        }
        return appContainer.createPlacesListView(places: sortedPlaces, selectedPlaceId: bindingSelectedPlaceId)
    }

    func createPlaceSheetView(place: Binding<PlaceUI>, detent: Binding<PresentationDetent>) -> PlaceSheetView {
        return appContainer.createPlaceSheetView(place: place, detent: detent)
    }

    func createPlaceEditView(place: PlaceUI) -> PlaceEditView {
        return appContainer.createPlaceEditView(place: place)
    }

    func createLookupPlacesView() -> LookupPlacesView {
        return appContainer.createLookupPlacesView()
    }
    
    func createLookupPlacesView(place: Binding<PlaceUI>) -> LookupPlacesView {
        return appContainer.createLookupPlacesView(place: place)
    }

    func createPlaceCreateView(coordinates: CLLocationCoordinate2D,
                               address: String,
                               name: String,
                               marker: String?,
                               tags: [UUID],
                               group: UUID?) -> PlaceCreateView {
        return appContainer.createPlaceCreateView(coordinates: coordinates,
                                                  address: address,
                                                  name: name,
                                                  marker: marker,
                                                  tags: tags,
                                                  group: group)
    }
    
    func createPlaceFilterView() -> PlaceFilterView {
        let filterBinding = Binding<PlaceFilter?> {
            self.currentFilter
        } set: { value in
            self.currentFilter = value
        }
        return appContainer.createPlaceFilterView(filter: filterBinding)
    }

    // MARK: Use cases
    func loadPlaces() async throws {
        let domainPlaces = try await fetchPlaces()
        places = domainPlaces.map { PlaceMapper.toUI($0) }
        mapReloadGen &+= 1   // force the MKMap annotations update
        return
    }
}
