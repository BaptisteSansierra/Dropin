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
    
    enum ViewError: Error, UserFacingError {
        case noResultFound
        case noAddress
        case notConnected
        case unexpected(Error)

        var messageTitle: LocalizedStringResource {
            "lookup_places_view.error.resolve.title"
        }
        var messageBody: LocalizedStringResource {
            switch self {
                case .noResultFound:
                    "lookup_places_view.resolve.error.empty"
                case .noAddress:
                    "lookup_places_view.resolve.error.no_address"
                case .notConnected:
                    "lookup_places_view.resolve.error.not_connected"
                case .unexpected(let error):
                    "lookup_places_view.resolve.error.unexpected_\(error.localizedDescription)"
            }
        }
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
    private(set) var lookupError: Error?  // a ContentUnavailableView is displayed if defined
    private(set) var searching = false
    private(set) var reachabilityService: any ReachabilityServiceProtocol
    private var searchTask: Task<Void, Never>?

    // True when requesting data for a specific place
    private(set) var resolving = false
    var resolvedPlace: LookupResolvedItem?
    var resolvedPlaceComputed: Bool = false
    var resolveError: ViewError?   // an alert is presented if defined

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
        defer { resolving = false }
        resolveError = nil
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
        } catch let error as ViewError {
            resolveError = error
        } catch {
            if error.isOffline || error.isTimeout {
                resolveError = .notConnected
            } else {
                resolveError = .unexpected(error)
            }
        }
    }
        
    // MARK: - private methods
    private func handleQueryChanges() {
        searchTask?.cancel()
        lookupError = nil
        guard query.count > 2 else {
            results = []
            searching = false
            return
        }
        searching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                results = try await addressLookupService.search(query: query)
                searching = false
            } catch is CancellationError {
                // Silent
            } catch {
                results = []
                lookupError = error
                searching = false
            }
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
