//
//  LookupPlacesViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/12/25.
//

import SwiftUI
import MapKit

struct LookupResolvedItem: Identifiable {
    enum PlaceType {
        case address
        case poi
    }
    var id: String {
        if #available(iOS 26.0, *) {
            "\(mapItem.location.coordinate.latitude)-\(mapItem.location.coordinate.longitude)"
        } else {
            "\(mapItem.placemark.coordinate.latitude)-\(mapItem.placemark.coordinate.longitude)"
        }
    }
    let type: PlaceType
    let mapItem: MKMapItem
    let address: String
    let coordinates: CLLocationCoordinate2D
    let distance: String?
    // POI specific
    let name: String?
    let pointOfInterestCategory: MKPointOfInterestCategory?
    let icon: Icon?

    init(mapItem: MKMapItem,
         address: String,
         coordinates: CLLocationCoordinate2D,
         distance: String?,
         name: String?) {
        self.type = .address
        self.mapItem = mapItem
        self.address = address
        self.coordinates = coordinates
        self.distance = distance
        if let name = name {
            if self.address.contains(name) {
                // name is the address, skip it
                self.name = nil
            } else {
                self.name = name
            }
        } else {
            self.name = nil
        }
        self.pointOfInterestCategory = nil
        self.icon = nil
    }

    init(mapItem: MKMapItem,
         address: String,
         coordinates: CLLocationCoordinate2D,
         distance: String?,
         name: String?,
         pointOfInterestCategory: MKPointOfInterestCategory?,
         icon: Icon?) {
        self.type = .poi
        self.mapItem = mapItem
        self.address = address
        self.coordinates = coordinates
        self.distance = distance
        self.name = name
        self.pointOfInterestCategory = pointOfInterestCategory
        self.icon = icon
    }
}

@MainActor
@Observable class LookupPlacesViewModel {
    
    enum ViewError: Error {
        case noResultFound
        case noAddress
    }
    
    // MARK: Properties
    var resultOffset: CGFloat = 0
    var resultStatus: LookupPlaceView.PresentationStatus = .pending
    var resultBgOpacity: CGFloat = 0

    var query: String = "" {
        didSet {
            guard query != oldValue else { return }
            guard reachabilityService.isConnected else { return }
            handleQueryChanges()
        }
    }
    private(set) var results: [LookupResult] = []
    private(set) var lookupError: Error?
    private(set) var searching = false
    private(set) var reachabilityService: ReachabilityService
    private var searchTask: Task<Void, Never>?

    private(set) var resolving = false
    var resolvedPlace: LookupResolvedItem?
    var resolvedPlaceComputed: Bool = false
    private(set) var resolveError: Error?

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var coordinator: MainCoordinator
    @ObservationIgnored private var addressLookupService: AddressLookupService
    @ObservationIgnored private var locationManager: LocationManager
    @ObservationIgnored private var updatePlace: UpdatePlace

    // MARK: - init
    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         addressLookupService: AddressLookupService,
         locationManager: LocationManager,
         reachabilityService: ReachabilityService,
         updatePlace: UpdatePlace) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.addressLookupService = addressLookupService
        self.locationManager = locationManager
        self.reachabilityService = reachabilityService
        self.updatePlace = updatePlace
    }
    
    // MARK: - Navigation
    func popToRoot() {
        coordinator.popToRoot()
    }

    func pushCreatePlaceFullView(lookupResolvedItem: LookupResolvedItem) {
        coordinator.pushCreatePlaceFullView(coordinates: lookupResolvedItem.coordinates,
                                            address: lookupResolvedItem.address,
                                            name: lookupResolvedItem.name ?? "",
                                            marker: nil,
                                            tags: [],
                                            group: nil)
    }
    
    func isEditMode() -> Bool {
        coordinator.path.contains(.placeEditView)
    }

    // MARK: - UI child
    func createLookupPlaceView(_ lookupResolvedItem: LookupResolvedItem,
                               place: Binding<PlaceUI?>,
                               status: Binding<LookupPlaceView.PresentationStatus>) -> LookupPlaceView {
        return appContainer.createLookupPlaceView(lookupResolvedItem: lookupResolvedItem,
                                                  place: place,
                                                  status: status)
    }
    
    // MARK: Use cases
    func updatePlace(_ place: PlaceUI) async throws {
        try await updatePlace.execute(PlaceMapper.toDomain(place))
    }

    // MARK: - public methods
    func updateQuery() {
        handleQueryChanges()
    }
    
    func resetResults() {
        results.removeAll()
        lookupError = nil
        searching = false
    }

    func resolvePlace(_ lookupResult: LookupResult) async {
        resolving = true
        let request = MKLocalSearch.Request(completion: lookupResult.localSearchCompletion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else {
                let error = ViewError.noResultFound
                throw error
            }
            resolvedPlace = try resolvedPlaceFromMapItem(item)
            resolvedPlaceComputed = true
            
            resolving = false
        } catch {
            resolveError = error
            resolving = false
        }
    }
        
    // MARK: - private methods
    private func handleQueryChanges() {
        searchTask?.cancel()
        
        guard query.count > 2 else {
            results = []
            lookupError = nil
            searching = false
            return
        }
        searching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            
            do {
                results = try await addressLookupService.search(query: query)
            } catch is CancellationError {
                // Silent
            } catch {
                results = []
                lookupError = error
            }
            searching = false
        }
    }
    
    private func resolvedPlaceFromMapItem(_ item: MKMapItem) throws -> LookupResolvedItem {
        // Get address
        guard let address = item.resolvedAddress() else {
            throw ViewError.noAddress
        }
        // Get distance
        let coordinates = item.resolvedCoordinates()
        let distance = locationManager.distanceStringTo(coordinates)
        
        // Return resolved item
        guard let poi = item.pointOfInterestCategory else {
            return LookupResolvedItem(mapItem: item,
                                      address: address,
                                      coordinates: coordinates,
                                      distance: distance,
                                      name: item.name)
        }
        return LookupResolvedItem(mapItem: item,
                                  address: address,
                                  coordinates: coordinates,
                                  distance: distance,
                                  name: item.name,
                                  pointOfInterestCategory: poi,
                                  icon: item.icon())
    }
}
