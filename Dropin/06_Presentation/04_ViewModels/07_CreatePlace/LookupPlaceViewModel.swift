//
//  LookupPlaceViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/12/25.
//

import Foundation

import SwiftUI
import MapKit

@MainActor
@Observable class LookupPlaceViewModel {
        
    // MARK: Properties
    var lookupResolvedItem: LookupResolvedItem
//    var resolvedResult: Result<LookupResolvedItem, Error>?
//    var searching: Bool = false
    //var showContent: Bool = false
    var cameraDistance: Double = 1000
    var camera: MapCameraPosition = .automatic

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var createPlace: CreatePlace

    // MARK: - init
    init(_ appContainer: AppContainer,
         createPlace: CreatePlace,
         lookupResolvedItem: LookupResolvedItem) {
        self.appContainer = appContainer
        self.createPlace = createPlace
        self.lookupResolvedItem = lookupResolvedItem
    }
//    
//TODO: resolve the place before showinh this view => no connectivity issues to handle
//    -> Push the LookupResolvedItem in navigation path
//    
//    TODO:    Remove all the NavigationLink => work with coordinator
//    cf: chat : "IOS dev questions v2"
//    
    
    // MARK: -
    /*
    func requestPlace() async {
        searching = true
        let request = MKLocalSearch.Request(completion: lookupResult.localSearchCompletion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else {
                let error = ViewError.noResultFound
                throw error
            }
            // TODO remove force
            resolvedResult = .success(try! resolvedResultFromMapItem(item))
            
            searching = false
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
            resolvedResult = .failure(error)
            searching = false
        }
    }
     */
    
    func zoomIn() {
        guard cameraDistance >= 125 else { return }
        cameraDistance /= 2
        updateCamera(coordinates: lookupResolvedItem.coordinates)
    }
    
    func zoomOut() {
        guard cameraDistance < 32_768_000 else { return }
        cameraDistance *= 2
        updateCamera(coordinates: lookupResolvedItem.coordinates)
    }

    func updateCamera(coordinates: CLLocationCoordinate2D) {
        camera = .camera(MapCamera(centerCoordinate: coordinates,
                                   distance: cameraDistance))
    }
}
