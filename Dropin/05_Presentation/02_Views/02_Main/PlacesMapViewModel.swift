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

//@MainActor
//@Observable protocol PlacesMapViewModelProtocol {
//
//}

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
    var mapConfig: MapConfig
    
//    // Used to communicate from ViewModel to ViewRepresentable
//    var mapActionBus: MapActionBus

    // Properties for creating a new place by address picking
    var pickingAddress: Bool = false {
        didSet {
            guard pickingAddress else { return }
            updatePlacePickerPositions()
            //mapActionBus.performAction(.updatePlacePickerPositions)
        }
    }
    var pickedAddress: String? = nil   // Used for creating a new place by address picking
    var addressPickerCoords: CLLocationCoordinate2D = .zero
    var addressPickerViewCoords: CGPoint = .zero
    
    // Properties for creating a new place by coordinates picking
    var pickingCoordinates: Bool = false {
        didSet {
            guard pickingCoordinates else { return }
            updatePlacePickerPositions()
            //mapActionBus.performAction(.updatePlacePickerPositions)
        }
    }
    var coordinatesPickerCoords: CLLocationCoordinate2D = .zero
    var coordinatesPickerViewCoords: CGPoint = .zero

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored var locationManager: LocationManager
    @ObservationIgnored private var addressPickingTask: Task<Void, Never>? = nil
    @ObservationIgnored var mapController: MapController

    // MARK: init
    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         locationManager: LocationManager) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
        self.mapConfig = MapConfig()
        //self.mapActionBus = MapActionBus(locationManager: locationManager)
        self.mapController = MapController()
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

    // MARK: - callbacks
    func onLongPress(coords: CLLocationCoordinate2D) {
        preparePlaceFromCoords(coords: coords)
        //viewModel.mapActionBus.performAction(.updateData)
        
        // Show the creation sheet
        showQuickCreateSheet.toggle()
        
        // Center map on new place
        //mapController.centerOn(coords)
        //centerOn(mapView, coords: coordinates, animated: true, sheetHeight: 400)
    }
    
    func onCameraUpdate(camera: MKMapCamera,
                        region: MKCoordinateRegion,
                        rect: MKMapRect) {
        
        // Update camera
        mapConfig.currentCamera = camera
        mapConfig.currentRegion = region
        mapConfig.currentRect = rect

        // Update picker position if needed
        guard pickingAddress || pickingCoordinates else { return }
        let cameraCenter = camera.centerCoordinate
        updatePlacePickerPositions(coords: cameraCenter)
    }

    func interactionStatus() -> PlacesMKMapVCR.InteractionStatus {
        return (!pickingAddress && !pickingCoordinates) ? .all : .none
    }
    
    // MARK: - Actions
    func centerOnUser() {
        guard let userCoords = locationManager.lastKnownLocation else { return }
        mapController.centerOn(userCoords,
                               withSheetOffset: false,
                               animated: true)
    }

    func centerOn(_ coords: CLLocationCoordinate2D) {
        mapController.centerOn(coords,
                               withSheetOffset: true,
                               animated: true)
    }
    
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
    
    func coordinatesPickerUpdate(_ newCoords: CLLocationCoordinate2D) {
        
        mapController.centerOn(newCoords, withSheetOffset: true)
        
        Task {
            try? await Task.sleep(for: .seconds(0.1))
            updatePlacePickerPositions(coords: newCoords)
        }

        /*
        mapActionBus.performAction(.centerOnCoords(coords: newCoords,
                                                   animated: false,
                                                   sheetHeight: DropinApp.ui.coordinatesPickerSheetHeight))
        Task {
            try? await Task.sleep(for: .seconds(0.1))
            mapActionBus.performAction(.updatePlacePickerPositions)
        }
         */
    }

    // MARK: - private
    private func reset() {
        tmpPlace = nil
        //mapActionBus.performAction(.updateData)
    }
    
    private func updatePlacePickerPositions() {
        updatePlacePickerPositions(coords: mapConfig.currentCamera.centerCoordinate)
    }

    private func updatePlacePickerPositions(coords: CLLocationCoordinate2D) {
        guard pickingAddress || pickingCoordinates else {
            assertionFailure()
            return
        }
        // Compute pickers coordinates
        let sheetHeight = pickingAddress ? DropinApp.ui.addressPickerSheetHeight : DropinApp.ui.coordinatesPickerSheetHeight
        let offset: CGFloat = (sheetHeight - DropinApp.ui.mainTabBarHeight) * -0.5

        guard let centerPoint = mapController.point(for: coords) else { // unproject(point) // mapView.convert(mapView.camera.centerCoordinate, toPointTo: mapView)
            assertionFailure("MapController not connected")
            return
        }
        let offsetPoint = CGPoint(x: centerPoint.x, y: centerPoint.y + offset)
        guard let offsetCoords = mapController.coordinate(at: offsetPoint) else { // project(offsetPoint) // mapView.convert(offsetPoint, toCoordinateFrom: mapView)
            assertionFailure("MapController not connected")
            return
        }
        
        if pickingAddress {
            addressPickerCoords = offsetCoords
            addressPickerViewCoords = offsetPoint
        } else {
            coordinatesPickerCoords = offsetCoords
            coordinatesPickerViewCoords = offsetPoint
        }
        pickedAddress = nil
        fetchAddress()
    }
    
    private func fetchAddress() {
        guard pickingAddress || pickingCoordinates else {
            assertionFailure()
            return
        }
        guard pickedAddress == nil else {
            // Already fetched for this position
            return
        }
        let coords = pickingAddress ? addressPickerCoords : coordinatesPickerCoords
        addressPickingTask?.cancel()
        addressPickingTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else {
                return
            }
            do {
                let address = try await fetchAddress(coords: coords)
                pickedAddress = address
            } catch {
                // TODO: handle error
                return
            }
        }
    }
    
    private func fetchAddress(coords: CLLocationCoordinate2D) async throws -> String {
        return try await LocationManager.lookUpAddress(coords: coords)
    }

}

// MARK: - Map Actions
// Map Actions are used to communicate from PlacesMapView to PlacesMapViewVCRepresentable
extension PlacesMapViewModel {
//    func clearSelection() {
//        mapActionBus.performAction(.clearSelection)
//    }
//    func centerOnUser() {
//        guard let coords = locationManager.lastKnownLocation else { return }
//        mapActionBus.performAction(.centerOnCoords(coords: coords))
//    }
//    func centerOnCoords(_ coords: CLLocationCoordinate2D, sheetHeight: CGFloat? = nil) {
//        mapActionBus.performAction(.centerOnCoords(coords: coords, sheetHeight: sheetHeight))
//    }
//    func reloadMapData() {
//        mapActionBus.performAction(.reloadData)
//    }
//    func manualSelectPlace(_ id: UUID) {
//        mapActionBus.performAction(.selectPlace(id: id))
//    }
}

// MARK: - MapActionBus
extension PlacesMapViewModel {
/*
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
 */
}

// MARK: - MapConfig
extension PlacesMapViewModel {

    @Observable class MapConfig {

        // MARK: - Published properties
        /// `settingsShown` show/hide the settings menu in the main map
        var settingsShown: Bool = false

        // MARK: - Non-observed camera state (written by map delegate — must NOT trigger SwiftUI re-renders)
        @ObservationIgnored public var currentCamera: MKMapCamera = .init()
        @ObservationIgnored public var currentRegion: MKCoordinateRegion = .zero
        @ObservationIgnored public var currentRect: MKMapRect = .null
    }
}
