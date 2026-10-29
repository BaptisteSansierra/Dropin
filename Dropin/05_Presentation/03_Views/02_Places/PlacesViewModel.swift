//
//  PlacesViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

@MainActor
@Observable class PlacesViewModel {
    
    // MARK: - Observed properties
    var coordinator: PlaceCoordinator
    var places: [PlaceUIModel] = [PlaceUIModel]()
    /*private(set)*/ var mapReloadGen: Int = 0    // bumps after each significant reload

    /// A draft place is created before being stored or discarded
    var draftPlace: PlaceUIModel? = nil
    /// A draft place created from an Apple POI may have an Apple category, used to suggest a category
    var draftPlacePoiCategory: MKPointOfInterestCategory? = nil
    /// A draft place created from an Apple POI may have a color, used to suggest a category
    var draftPlacePoiColor: Color? = nil

    var syncStatus: SyncStatus
    var reachabilityService: any ReachabilityServiceProtocol

    /// Filter active places (aka not deleted)
    var activePlaces: [PlaceUIModel] {
        return places.filter({ $0.isActive })
    }

    /// Places filtered with `currentFilter`
    var filteredPlaces: [PlaceUIModel] {
        guard let filter = currentFilter else { return places }
        return filter.apply(places)
    }

    /// Places filtered with `currentFilter` ans sorted with `sortPolicy`
    var sortedPlaces: [PlaceUIModel] {
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
    
    /// Selected tab: 0=map, 1=list
    var selectedTab: Int = 0

    /// Location access not granted alert toggle
    var showAuthLocAlert = false

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored var locationManager: LocationManager
    @ObservationIgnored private var fetchPlaces: FetchPlaces
    @ObservationIgnored private var placeSources: [Place] = [Place]()

    // MARK: init
    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         locationManager: LocationManager,
         fetchPlaces: FetchPlaces,
         syncStatus: SyncStatus,
         reachabilityService: any ReachabilityServiceProtocol) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
        self.fetchPlaces = fetchPlaces
        self.syncStatus = syncStatus
        self.reachabilityService = reachabilityService
    }

    // MARK: actions
    func updateMapAnnotations() {
        mapReloadGen &+= 1   // force the MKMap annotations update
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
        let bindingDraftPlace = Binding<PlaceUIModel?>(
            get: {
                return self.draftPlace
            }, set: { value in
                self.draftPlace = value
            })
        let bindingDraftPlacePoiCategory = Binding<MKPointOfInterestCategory?>(
            get: {
                return self.draftPlacePoiCategory
            }, set: { value in
                self.draftPlacePoiCategory = value
            })
        let bindingDraftPlacePoiColor = Binding<Color?>(
            get: {
                return self.draftPlacePoiColor
            }, set: { value in
                self.draftPlacePoiColor = value
            })
        let bindingFilter = Binding<PlaceFilter?> {
            self.currentFilter
        } set: { newValue in
            self.currentFilter = newValue
        }
        return appContainer.createPlacesMapView(places: { self.filteredPlaces },
                                                allPlacesCount: activePlaces.count,
                                                draftPlace: bindingDraftPlace,
                                                draftPlacePoiCategory: bindingDraftPlacePoiCategory,
                                                draftPlacePoiColor: bindingDraftPlacePoiColor,
                                                selectedPlaceId: bindingSelectedPlaceId,
                                                filter: bindingFilter,
                                                isParentPresenting: bindingIsPresenting,
                                                showingCreatePlaceMenu: bindingShowingCreatePlaceMenu,
                                                mapReloadGen: mapReloadGen,
                                                navBarHeight: navBarHeight,
                                                isActiveTab: selectedTab == 0)
    }
    
    func createPlacesListView() -> PlacesListView {
        let bindingSelectedPlaceId = Binding<UUID?> {
            self.selectedPlaceId
        } set: { newValue in
            self.selectedPlaceId = newValue
        }
        let bindingFilter = Binding<PlaceFilter?> {
            self.currentFilter
        } set: { newValue in
            self.currentFilter = newValue
        }
        return appContainer.createPlacesListView(places: sortedPlaces,
                                                 allPlacesCount: activePlaces.count,
                                                 selectedPlaceId: bindingSelectedPlaceId,
                                                 filter: bindingFilter)
    }

    func createPlaceSheetView(place: Binding<PlaceUIModel>, detent: Binding<PresentationDetent>) -> PlaceSheetView {
        // Display the "Show on map" button only if view is presented from list
        let mapAction = {
            self.selectedTab = 0
            self.selectedPlaceId = place.id
        }
        return appContainer.createPlaceSheetView(place: place,
                                                 mapAction: selectedTab == 1 ? mapAction : nil,
                                                 detent: detent)
    }

    func createPlaceEditView(place: PlaceUIModel) -> PlaceEditView {
        return appContainer.createPlaceEditView(place: place)
    }

    func createLookupPlacesView(draftPlace: Binding<PlaceUIModel?>,
                                draftPlacePoiCategory: Binding<MKPointOfInterestCategory?>,
                                draftPlacePoiColor: Binding<Color?>) -> LookupPlacesView {
        return appContainer.createLookupPlacesView(draftPlace: draftPlace,
                                                   draftPlacePoiCategory: draftPlacePoiCategory,
                                                   draftPlacePoiColor: draftPlacePoiColor)
    }
    
    func createLookupPlacesView(place: Binding<PlaceUIModel>) -> LookupPlacesView {
        return appContainer.createLookupPlacesView(place: place)
    }

//    func createPlaceCreateView(coordinates: CLLocationCoordinate2D,
//                               address: String?,
//                               name: String,
//                               marker: String?,
//                               tags: [UUID],
//                               category: UUID?) -> PlaceCreateView {
    func createPlaceCreateView() -> PlaceCreateView {
        guard let draftPlace = draftPlace else {
            fatalError("undefined draftPlace")
        }
        return appContainer.createPlaceCreateView(place: draftPlace)
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
        let newPlaces = try await fetchPlaces()
        let newPlacesUI = newPlaces.map { PlaceMapper.toUI($0) }
        
        // loadPlaces() gets called from several independent triggers (view appear, sync completion, place edit/create)
        // that could be costly to update pins each time. Only do it if necessary
        let oldSignature = Set(placeSources.map { "\($0.id)-\($0.updatedAt)" })
        let newSignature = Set(newPlaces.map { "\($0.id)-\($0.updatedAt)" })

        guard oldSignature != newSignature else {
            // NOTE: an update on category or tags color/icon would not be detected here
            // Not an issue at the moment as it's not editable from the place section currently
            return
        }
        places = newPlacesUI
        updateMapAnnotations()
        placeSources = newPlaces
    }
}
