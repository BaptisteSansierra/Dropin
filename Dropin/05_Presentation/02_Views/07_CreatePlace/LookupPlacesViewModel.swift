//
//  LookupPlacesViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/12/25.
//

import SwiftUI
import MapKit

@MainActor
@Observable class LookupPlacesViewModel {
    
    enum ViewError: Error {
        case noResultFound
        case noAddress
    }
    
    // MARK: Properties
    var resultOffset: CGFloat = 0
    var resultStatus: LookupPlaceSheetView.PresentationStatus = .pending
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
    private(set) var reachabilityService: any ReachabilityServiceProtocol
    private var searchTask: Task<Void, Never>?

    private(set) var resolving = false
    var resolvedPlace: LookupResolvedItem?
    var resolvedPlaceComputed: Bool = false
    private(set) var resolveError: Error?

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var coordinator: PlaceCoordinator
    @ObservationIgnored private var addressLookupService: AddressLookupService
    @ObservationIgnored private var locationManager: LocationManager
    @ObservationIgnored private var updatePlace: UpdatePlace

    // MARK: - init
    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         addressLookupService: AddressLookupService,
         locationManager: LocationManager,
         reachabilityService: any ReachabilityServiceProtocol,
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

    func isEditMode() -> Bool {
        coordinator.path.contains(.placeEditView)
    }
    
    // MARK: Use cases
    func updatePlace(_ place: PlaceUIModel) async throws {
        try await updatePlace(PlaceMapper.toDomain(place))
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
            resolvedPlace = try resolvedPlaceFromMapItem(item, isPOI: lookupResult.isPOI)
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
    
    private func resolvedPlaceFromMapItem(_ item: MKMapItem, isPOI: Bool) throws -> LookupResolvedItem {
        // Get address
        guard let address = item.resolvedAddress() else {
            throw ViewError.noAddress
        }
        // Get distance
        let coordinates = item.resolvedCoordinates()
        let distance = locationManager.distanceStringTo(coordinates)
        
        // Return resolved item
        return LookupResolvedItem(mapItem: item,
                                  isPOI: isPOI,
                                  address: address,
                                  coordinates: coordinates,
                                  distance: distance)
    }
}
