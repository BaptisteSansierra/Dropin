//
//  PlacesMapViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit

@MainActor
@Observable class PlacesMapViewModel {
    
    // MARK: - Observed Properties
    private(set) var coordinator: MainCoordinator
    // Used for creating a new place
    var tmpPlace: PlaceUI? = nil
    // Alerts toggles
    var showAuthLocAlert = false
    var showQuickCreateSheet = false
    // Map settings
    var mapSettings: MapSettings
    // Used to communicate from ViewModel to ViewRepresentable
    var mapActionBus: MapActionBus

    // Properties for creating a new place by address picking
    var pickingAddress: Bool = false {
        didSet {
            guard pickingAddress else { return }
            mapActionBus.performAction(.updatePlacePickerPositions)
        }
    }
    var pickedAddress: String? = nil   // Used for creating a new place by address picking
    var addressPickerCoords: CLLocationCoordinate2D = .zero
    var addressPickerViewCoords: CGPoint = .zero
    
    // Properties for creating a new place by coordinates picking
    var pickingCoordinates: Bool = false {
        didSet {
            guard pickingCoordinates else { return }
            mapActionBus.performAction(.updatePlacePickerPositions)
        }
    }
    var coordinatesPickerCoords: CLLocationCoordinate2D = .zero
    var coordinatesPickerViewCoords: CGPoint = .zero

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored var locationManager: LocationManager

    // MARK: init
    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         locationManager: LocationManager) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
        self.mapSettings = MapSettings()
        self.mapActionBus = MapActionBus(locationManager: locationManager)
    }
    
    // MARK: Navigation
    func pushLookupPlacesView() {
        coordinator.pushLookupPlacesView()
    }
    
    // MARK: - UI child
    func createPlaceCreateQuickView() -> PlaceCreateQuickView {
        guard let tmpPlace = tmpPlace else {
            fatalError("temporary place undefined")
        }
        return appContainer.createPlaceCreateQuickView(place: tmpPlace)
    }
        
    // MARK: - Actions
    func preparePlaceFromCoords(coords: CLLocationCoordinate2D) {
        let createdPlace = PlaceUI(coordinates: coords)
        tmpPlace = createdPlace
    }

    func preparePlaceFromAddress(coords: CLLocationCoordinate2D,
                                 address: String?) {
        let createdPlace = PlaceUI(coordinates: coords)
        if let address = address {
            createdPlace.address = address
        }
        tmpPlace = createdPlace
    }

    func discardCreation() {
        reset()
    }

    func fetchAddress(coords: CLLocationCoordinate2D) async throws -> String {
        return try await LocationManager.lookUpAddress(coords: coords)
    }
    
    func coordinatesPickerUpdate(_ newCoords: CLLocationCoordinate2D) {
        mapActionBus.performAction(.centerOnCoords(coords: newCoords,
                                                   animated: false,
                                                   sheetHeight: DropinApp.ui.coordinatesPickerSheetHeight))
        Task {
            try? await Task.sleep(for: .seconds(0.1))
            mapActionBus.performAction(.updatePlacePickerPositions)
        }
    }

    // MARK: - private
    private func reset() {
        tmpPlace = nil
        mapActionBus.performAction(.updateData)
    }
}

// MARK: - Map Actions
// Map Actions are used to communicate from PlacesMapView to PlacesMapViewVCRepresentable
extension PlacesMapViewModel {
    func clearSelection() {
        mapActionBus.performAction(.clearSelection)
    }
    func centerOnUser() {
        guard let coords = locationManager.lastKnownLocation else { return }
        mapActionBus.performAction(.centerOnCoords(coords: coords))
    }
    func centerOnCoords(_ coords: CLLocationCoordinate2D, sheetHeight: CGFloat? = nil) {
        mapActionBus.performAction(.centerOnCoords(coords: coords, sheetHeight: sheetHeight))
    }
    func reloadMapData() {
        mapActionBus.performAction(.reloadData)
    }
    func manualSelectPlace(_ id: UUID) {
        mapActionBus.performAction(.selectPlace(id: id))
    }
}

// MARK: - MapActionBus
extension PlacesMapViewModel {

    /// Used to communicate from ViewModel to ViewRepresentable
    @Observable class MapActionBus {

        enum MapAction: Equatable {
            case clearSelection
            case centerOnCoords(coords: CLLocationCoordinate2D, animated: Bool = true, sheetHeight: CGFloat? = nil)
            case reloadData
            case updateData
            case updatePlacePickerPositions
            case selectPlace(id: UUID)
        }

        @ObservationIgnored private var locationManager: LocationManager

        // Observed by ViewRepresentable
        var currentAction: MapAction?

        fileprivate init(locationManager: LocationManager) {
            self.locationManager = locationManager
        }
        
        func performAction(_ action: MapAction) {
            // Send an action to ViewRepresentable
            currentAction = action
        }
    }
}

// MARK: - MapSettings
extension PlacesMapViewModel {

    @Observable class MapSettings {

        // MARK: - Published properties
        /// `settingsShown` show/hide the settings menu in the main map
        var settingsShown: Bool = false

        // MARK: - Non-observed camera state (written by map delegate — must NOT trigger SwiftUI re-renders)
        @ObservationIgnored public var currentCamera: MKMapCamera = .init()
        @ObservationIgnored public var currentRegion: MKCoordinateRegion = .zero
        @ObservationIgnored public var currentRect: MKMapRect = .null
    }
}
