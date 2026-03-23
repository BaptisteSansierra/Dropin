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
    
    /// show/hide the 'create new place' menu
    var showingCreatePlaceMenu: Bool = false

    /// Should be set to true when showing sidebar / presenting add place menu / ...
    var isPresenting: Bool = false

    // /////////////////////
    // Moved from PlacesListViewModel in order to define ToolBar in MainView
    // currently duplicated, should be solved somehow
    var grouped = false
    enum SortMode: Int {
        case distance = 0
        case alphabetically = 1
        case creationDate = 2
    }
    var sortMode: SortMode = .distance
    // /////////////////////
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var getPlaces: GetPlaces
    
    init(_ appContainer: AppContainer, coordinator: MainCoordinator, getPlaces: GetPlaces) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.getPlaces = getPlaces
    }

//    // MARK: Navigation
//    func pushLookupPlacesView() {
//        coordinator.pushLookupPlacesView()
//    }

    // MARK: UI Child
    func createPlacesMapView() -> PlacesMapView {
        let bindingPlaces = Binding<[PlaceUI]>(
            get: {
                return self.places
            }, set: { value in
                self.places = value
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
                                                showingCreatePlaceMenu: bindingShowingCreatePlaceMenu)
    }
    
    func createPlacesListView() -> PlacesListView {
        let bindingPlaces = Binding<[PlaceUI]>(
            get: {
                return self.places
            }, set: { value in
                self.places = value
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
    
    func createDropAPinView() -> DropAPinView {
        return appContainer.createDropAPinView()
    }

    // MARK: Use cases
    func loadPlaces() async throws {
        let domainPlaces = try await getPlaces.execute()
        places = domainPlaces.map { PlaceMapper.toUI($0) }
    }
}
