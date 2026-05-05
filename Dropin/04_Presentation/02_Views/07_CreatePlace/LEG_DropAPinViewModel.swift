//
//  DropAPinView.swift
//  Dropin
//
//  Created by baptiste sansierra on 6/3/26.
//

#if false
import SwiftUI
import MapKit
import CoreLocation

@MainActor
@Observable class DropAPinViewModel {
    
    var camera: MapCameraPosition
    var cameraDistance: Double = 1000
    var centerPosition: CLLocationCoordinate2D = .zero
    var navBarHeight: CGFloat = 0

    private var latitudeStr: String
    private var longitudeStr: String
    var address: String = ""

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var coordinator: MainCoordinator
    @ObservationIgnored var locationManager: LocationManager
    @ObservationIgnored private let createPlace: CreatePlace
    
    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         locationManager: LocationManager,
         createPlace: CreatePlace) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
        self.createPlace = createPlace
        
        if let loc = locationManager.lastKnownLocation {
            let region = MKCoordinateRegion(center: loc,
                                            span: MKCoordinateSpan.init(squareDelta: 0.001))
            self.camera = MapCameraPosition.region(region)
            self.centerPosition = loc
            self.latitudeStr  = String(format: "%.6f", loc.latitude)
            self.longitudeStr = String(format: "%.6f", loc.longitude)

        } else {
            self.camera = MapCameraPosition.region(.barcelona)
            let loc = CLLocationCoordinate2D.barcelona
            self.centerPosition = loc
            self.latitudeStr  = String(format: "%.6f", loc.latitude)
            self.longitudeStr = String(format: "%.6f", loc.longitude)
        }

    }
    
    // MARK: - Actions
    func zoomIn() {
        guard cameraDistance >= 125 else { return }
        cameraDistance /= 2
        updateCamera(coordinates: centerPosition)
    }
    
    func zoomOut() {
        guard cameraDistance < 32_768_000 else { return }
        cameraDistance *= 2
        updateCamera(coordinates: centerPosition)
    }

    func updateCamera(coordinates: CLLocationCoordinate2D) {
        camera = .camera(MapCamera(centerCoordinate: coordinates,
                                   distance: cameraDistance))
    }
    
    func didUpdateCamera(_ context : MapCameraUpdateContext) {
        centerPosition = context.camera.centerCoordinate
        cameraDistance = context.camera.distance
        self.latitudeStr = String(format: "%.6f", centerPosition.latitude)
        self.longitudeStr = String(format: "%.6f", centerPosition.longitude)
    }
}
#endif
