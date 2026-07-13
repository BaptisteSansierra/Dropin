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
    var cameraDistance: Double = 1000
    var camera: MapCameraPosition = .automatic

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var createPlace: CreatePlace
    @ObservationIgnored private var coordinator: PlaceCoordinator

    // MARK: - init
    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         createPlace: CreatePlace,
         lookupResolvedItem: LookupResolvedItem) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.createPlace = createPlace
        self.lookupResolvedItem = lookupResolvedItem
    }

    // MARK: - Navigation
    /*
    func pushCreatePlaceFullView(lookupResolvedItem: LookupResolvedItem) {
        coordinator.pushCreatePlaceFullView(coordinates: lookupResolvedItem.coordinates,
                                            address: lookupResolvedItem.address,
                                            name: lookupResolvedItem.name ?? "",
                                            marker: nil,
                                            tags: [],
                                            group: nil)
    }
*/
    
    // MARK: - Actions
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
