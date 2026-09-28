//
//  PlacesViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation
import SwiftUI
import CoreLocation

@MainActor
@Observable class PlacesViewModel {
    
    // MARK: - Observed properties
    var coordinator: PlaceCoordinator
    var places: [PlaceUIModel] = [PlaceUIModel]()
    /*private(set)*/ var mapReloadGen: Int = 0    // bumps after each significant reload

    var syncStatus: SyncStatus
    var reachabilityService: ReachabilityService

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
    var selectedTab: Int = 0

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var locationManager: LocationManager
    @ObservationIgnored private var fetchPlaces: FetchPlaces

    // MARK: init
    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         locationManager: LocationManager,
         fetchPlaces: FetchPlaces,
         syncStatus: SyncStatus,
         reachabilityService: ReachabilityService) {
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
        return appContainer.createPlacesMapView(places: filteredPlaces,
                                                selectedPlaceId: bindingSelectedPlaceId,
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
        return appContainer.createPlacesListView(places: sortedPlaces, selectedPlaceId: bindingSelectedPlaceId)
    }

    func createPlaceSheetView(place: Binding<PlaceUIModel>, detent: Binding<PresentationDetent>) -> PlaceSheetView {
        return appContainer.createPlaceSheetView(place: place, detent: detent)
    }

    func createPlaceEditView(place: PlaceUIModel) -> PlaceEditView {
        return appContainer.createPlaceEditView(place: place)
    }

    func createLookupPlacesView() -> LookupPlacesView {
        return appContainer.createLookupPlacesView()
    }
    
    func createLookupPlacesView(place: Binding<PlaceUIModel>) -> LookupPlacesView {
        return appContainer.createLookupPlacesView(place: place)
    }

    func createPlaceCreateView(coordinates: CLLocationCoordinate2D,
                               address: String?,
                               name: String,
                               marker: String?,
                               tags: [UUID],
                               category: UUID?) -> PlaceCreateView {
        return appContainer.createPlaceCreateView(coordinates: coordinates,
                                                  address: address,
                                                  name: name,
                                                  marker: marker,
                                                  tags: tags,
                                                  category: category)
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
        let newPlaces = try await fetchPlaces().map { PlaceMapper.toUI($0) }
        
        var dups: [Place: Int] = [:]
        for p in newPlaces {
            let dp = PlaceMapper.toDomain(p)
            if let _ = dups[dp] { continue }
            dups[dp] = newPlaces.filter({ $0.id == dp.id }).count
        }
        let rdups = dups.filter { $1 > 1 }
        for p in rdups.keys {
            print("PLACE '\(p.name)'  DUP(\(rdups[p]))")
        }
        

        // loadPlaces() gets called from several independent triggers (view appear,
        // sync completion, place edit/create) that can fire in a tight cluster —
        // unconditionally bumping mapReloadGen on every call forced a full
        // annotation wipe-and-recreate each time, even when nothing had changed.
        let oldSignature = Set(places.map { "\($0.id)-\($0.updatedAt)" })
        let newSignature = Set(newPlaces.map { "\($0.id)-\($0.updatedAt)" })

        places = newPlaces
        if oldSignature != newSignature {
            updateMapAnnotations()
        }
    }
}
