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
    
    var coordinator: MainCoordinator
    var places: [PlaceUI] = [PlaceUI]()
    var filteredPlaces: [PlaceUI] = [PlaceUI]()
    var sortedPlaces: [PlaceUI] = [PlaceUI]()

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
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var locationManager: LocationManager
    @ObservationIgnored private var getPlaces: GetPlaces

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         locationManager: LocationManager,
         getPlaces: GetPlaces) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
        self.getPlaces = getPlaces
    }

//    // MARK: Navigation
//    func pushLookupPlacesView() {
//        coordinator.pushLookupPlacesView()
//    }

    // MARK: UI Child
    func createPlacesMapView(navBarHeight: CGFloat) -> PlacesMapView {
        let bindingPlaces = Binding<[PlaceUI]>(
            get: {
                return self.filteredPlaces
            }, set: { value in
                assertionFailure("Child is not supposed to edit the full list")
                // Child is not supposed to edit the full place list, only one place by one (EDIT)
                // FIXME: as an improvement => do not pass a binding but a simple list + a binding to selectedPlace
                // MainViewModel would store selectedPlace instead of both PlaceListViewModel/MapListViewModel
            })
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
        return appContainer.createPlacesMapView(places: bindingPlaces,
                                                isParentPresenting: bindingIsPresenting,
                                                showingCreatePlaceMenu: bindingShowingCreatePlaceMenu,
                                                navBarHeight: navBarHeight)
    }
    
    func createPlacesListView() -> PlacesListView {
        let bindingPlaces = Binding<[PlaceUI]>(
            get: {
                return self.sortedPlaces
            }, set: { value in
                assertionFailure("Child is not supposed to edit the full list")
                // Child is not supposed to edit the full place list, only one place by one (EDIT)
                // FIXME: as an improvement => do not pass a binding but a simple list + a binding to selectedPlace
            })
        return appContainer.createPlacesListView(places: bindingPlaces)
    }

    func createPlaceEditView(place: Binding<PlaceUI>) -> PlaceEditView {
        return appContainer.createPlaceEditView(place: place)
    }

    func createLookupPlacesView() -> LookupPlacesView {
        return appContainer.createLookupPlacesView()
    }

    func createLookupPlacesView(placeId: UUID) -> LookupPlacesView {
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

    #if false
    func createDropAPinView() -> DropAPinView {
        return appContainer.createDropAPinView()
    }
    #endif

    // MARK: Use cases
    func loadPlaces() async throws {
        let domainPlaces = try await getPlaces.execute()
        places = domainPlaces.map { PlaceMapper.toUI($0) }
        // update dependency
        updateFiltering()
    }
    
    // MARK: Actions
    func updateFiltering() {
        defer {
            // update dependency
            updateSorting()
        }
        guard let filter = currentFilter else {
            filteredPlaces = places
            return
        }
        filteredPlaces = filter.apply(places)
    }

    func updateSorting() {
        sortedPlaces = sortPolicy.apply(filteredPlaces, userPosition: locationManager.lastKnownLocation)
    }
}
