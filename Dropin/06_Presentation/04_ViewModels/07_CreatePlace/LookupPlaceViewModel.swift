//
//  LookupPlaceViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/12/25.
//

import Foundation

import SwiftUI
import MapKit
import Contacts

protocol LookupResolvedItem {
    var mapItem: MKMapItem { get }
    var address: String { get }
    var location: CLLocationCoordinate2D { get }
    var distance: String? { get }
}

struct LookupSimpleResolvedItem: LookupResolvedItem {
    let mapItem: MKMapItem
    let address: String
    let location: CLLocationCoordinate2D
    let distance: String?
}

struct LookupPOIResolvedItem: LookupResolvedItem {
    let mapItem: MKMapItem
    let name: String?
    let pointOfInterestCategory: MKPointOfInterestCategory
    let icon: Icon
    let address: String
    let location: CLLocationCoordinate2D
    let distance: String?
}

@MainActor
@Observable class LookupPlaceViewModel {
    
    // MARK: Properties
    var lookupResult: LookupResult
    var resolvedResult: Result<LookupResolvedItem, Error>?
    var searching: Bool = false
    var showContent: Bool = false
    var cameraDistance: Double = 1000
    var camera: MapCameraPosition = .automatic

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var createPlace: CreatePlace
    @ObservationIgnored private var locationManager: LocationManager

    // MARK: - init
    init(_ appContainer: AppContainer,
         createPlace: CreatePlace,
         locationManager: LocationManager,
         lookupResult: LookupResult) {
        self.appContainer = appContainer
        self.createPlace = createPlace
        self.locationManager = locationManager
        self.lookupResult = lookupResult
    }
    
    // MARK: -
    func requestPlace() async {
        searching = true
        let request = MKLocalSearch.Request(completion: lookupResult.localSearchCompletion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else {
                // TODO
                let error = DataError.duplicate(msg: "TODO: create specific errror")
                throw error
            }
            // TODO remove force
            resolvedResult = .success(try! resolvedResultFromMapItem(item))
            
            searching = false
            showContent = true


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
            resolvedResult = .failure(error)
            searching = false
        }
    }
    
    func zoomIn() {
        guard cameraDistance >= 125 else { return }
        switch resolvedResult {
            case .success(let success):
                cameraDistance /= 2
                updateCamera(coordinates: success.location)
            default:
                return
        }
    }
    
    func zoomOut() {
        guard cameraDistance < 32_768_000 else { return }
        switch resolvedResult {
            case .success(let success):
                cameraDistance *= 2
                updateCamera(coordinates: success.location)
            default:
                return
        }
    }

    func updateCamera(coordinates: CLLocationCoordinate2D) {
        camera = .camera(MapCamera(centerCoordinate: coordinates,
                                   distance: cameraDistance))
    }
    
    private func resolvedResultFromMapItem(_ item: MKMapItem) throws -> LookupResolvedItem {
        // Get address
        var address: String?
        if #available(iOS 26.0, *) {
            if let itemAddress = item.address {
                address = itemAddress.fullAddress
            }
        } else {
            if let postalAddress = item.placemark.postalAddress {
                let formatter = CNPostalAddressFormatter()
                address = formatter.string(from: postalAddress)
            }
        }
        guard let address = address else {
            // TODO
            throw DataError.duplicate(msg: "TODO:: implement error accordingly")
        }
        
        // Get lat/long
        var location = CLLocationCoordinate2D.zero
        if #available(iOS 26.0, *) {
            location = item.location.coordinate
        } else {
            location = item.placemark.coordinate
        }
        //let distance = locationManager.distanceStringTo(location)
        let distance = "15.5 km"

        guard let poi = item.pointOfInterestCategory else {
            return LookupSimpleResolvedItem(mapItem: item,
                                            address: address,
                                            location: location,
                                            distance: distance)
        }
        return LookupPOIResolvedItem(mapItem: item,
                                     name: item.name,
                                     pointOfInterestCategory: poi,
                                     icon: item.icon(),
                                     address: address,
                                     location: location,
                                     distance: distance)
    }
}
