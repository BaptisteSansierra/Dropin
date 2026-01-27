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
         distance: String?) {
        self.type = .address
        self.mapItem = mapItem
        self.address = address
        self.coordinates = coordinates
        self.distance = distance
        self.name = nil
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
    @ObservationIgnored private var addressLookupService: AddressLookupService
    @ObservationIgnored private var locationManager: LocationManager

    // MARK: - init
    init(_ appContainer: AppContainer,
         addressLookupService: AddressLookupService,
         locationManager: LocationManager,
         reachabilityService: ReachabilityService) {
        self.appContainer = appContainer
        self.addressLookupService = addressLookupService
        self.locationManager = locationManager
        self.reachabilityService = reachabilityService
    }
    
    // MARK: -
    func updateQuery() {
        handleQueryChanges()
    }
    
    func resetResults() {
        results.removeAll()
        lookupError = nil
        searching = false
    }
    
    // MARK: - UI child
    func createLookupPlaceView(_ lookupResolvedItem: LookupResolvedItem,
                               status: Binding<LookupPlaceView.PresentationStatus>) -> LookupPlaceView {
        return appContainer.createLookupPlaceView(lookupResolvedItem: lookupResolvedItem,
                                                  status: status)
    }
    
    // MARK: - public methods
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
            //showContent = true
            
            
            //            print("FIRST LOC FOUND : ")
            //            print("Name: \(response.mapItems.first!.name)")
            //            if #available(iOS 26.0, *) {
            //                print("Address: \(response.mapItems.first!.address)")
            //            } else {
            //                if let postalAddress = response.mapItems.first!.placemark.postalAddress {
            //                    let formatter = CNPostalAddressFormatter()
            //                    let addressString = formatter.string(from: postalAddress)
            //                    print("Address Postal: \(addressString)")
            //                }
            //            }
            //            print("Phone: \(response.mapItems.first!.phoneNumber)")
            //            print("URL: \(response.mapItems.first!.url)")
            
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
                                      distance: distance)
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
