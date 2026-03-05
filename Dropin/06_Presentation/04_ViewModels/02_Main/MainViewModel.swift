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
        return appContainer.createPlacesMapView(places: bindingPlaces,
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
    
    /*
    // TODO: to be replaced ?
    func createPlaceDetailsView(place: Binding<PlaceUI>, editMode: PlaceEditMode) -> PlaceDetailsView {
        return appContainer.createPlaceDetailsView(place: place, editMode: editMode)
    }
     */
    
    func createPlaceEditView(place: Binding<PlaceUI>) -> PlaceEditView {
        return appContainer.createPlaceEditView(place: place)
    }

    func createLookupPlacesView() -> LookupPlacesView {
        return appContainer.createLookupPlacesView()
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

    /*
    func createCreatePlaceFullView(coordinates: CLLocationCoordinate2D,
                                   address: String,
                                   name: String,
                                   marker: String?,
                                   tags: [String],
                                   group: String?) -> CreatePlaceFullView {
        return appContainer.createCreatePlaceFullView(coordinates: coordinates,
                                                      address: address,
                                                      name: name,
                                                      marker: marker,
                                                      tags: tags,
                                                      group: group)
    }
     */

    // MARK: Use cases
    func loadPlaces() async throws {
        let domainPlaces = try await getPlaces.execute()
        places = domainPlaces.map { PlaceMapper.toUI($0) }
    }
}
