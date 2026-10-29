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


struct IdentifiablePOI: Identifiable {
    let id = UUID()
    let annotation: MKMapFeatureAnnotation
}

@MainActor
@Observable class PlacesMapViewModel {

    // MARK: - Observed Properties
    private(set) var coordinator: PlaceCoordinator

    var syncStatus: SyncStatus

    // Alerts toggles
    var showAuthLocAlert = false
    var showQuickCreateSheet = false
    var quickCreateResult: PlaceCreateQuickView.Result = .none

    // Set when the draft place matches an existing place (same name+coords, or same applePlaceID)
    var isPresentingDuplicatingPlace = false
    var duplicatingPlace: PlaceUIModel?
    // Set when the draft place sits within 3m of a different existing place
    var isPresentingOverlapingPlace = false
    var overlapingPlace: PlaceUIModel?

    var selectedApplePOI: MKMapFeatureAnnotation?
    var selectedIdfApplePOI: IdentifiablePOI?
    var presentApplePOI = false
    
    
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
    var pickingAddressWithCoords = false
    var pickedAddress: String? = nil   // Used for creating a new place by address picking
    var addressPickerCoords: CLLocationCoordinate2D = .zero
    var addressPickerViewCoords: CGPoint = .zero
    var fetchingAddressPicker = false
    
    // Map configuration
    var launchConfig: PlacesMKMapVCR.Configuration {
        var config = PlacesMKMapVCR.Configuration.interactive
        if let hardStartRegion = DropinApp.map.hardStartRegion {
            config.positionAtLaunch = .region(region: hardStartRegion)
            return config
        }
        guard let lastRegion = appContainer.lastMapRegion else {
            return .interactive
        }
        config.positionAtLaunch = .region(region: lastRegion)
        return config
    }

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored var locationManager: LocationManager
    @ObservationIgnored private var addressPickingTask: Task<Void, Never>? = nil
    @ObservationIgnored var mapController: MapController
    @ObservationIgnored private var mapCamera: MapCamera

    // MARK: init
    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         locationManager: LocationManager,
         syncStatus: SyncStatus) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
        self.syncStatus = syncStatus
        self.mapCamera = MapCamera()
        //self.mapActionBus = MapActionBus(locationManager: locationManager)
        self.mapController = MapController()
    }

    // MARK: Navigation
    func pushLookupPlacesView() {
        coordinator.pushLookupPlacesView()
    }
    
    // MARK: - UI child
    func createPlaceCreateQuickView(draftPlace: Binding<PlaceUIModel?>,
                                    draftPlacePoiCategory: MKPointOfInterestCategory?,
                                    draftPlacePoiColor: Color?) -> PlaceCreateQuickView {
        guard let draftPlace = draftPlace.wrappedValue else {
            fatalError("draft place undefined")
        }
        quickCreateResult = .none
        let quickCreateResultBinding = Binding {
            self.quickCreateResult
        } set: { value in
            self.quickCreateResult = value
        }
        return appContainer.createPlaceCreateQuickView(place: draftPlace,
                                                       result: quickCreateResultBinding,
                                                       poiCategory: draftPlacePoiCategory,
                                                       poiColor: draftPlacePoiColor)
    }

    func createApplePOISheetView(draftPlace: Binding<PlaceUIModel?>,
                                 draftPlacePoiCategory: Binding<MKPointOfInterestCategory?>,
                                 draftPlacePoiColor: Binding<Color?>) -> ApplePOISheetView {
        guard let selectedApplePOI = selectedApplePOI else {
            fatalError("selectedApplePOI undefined for ApplePOISheetView")
        }
        return appContainer.createApplePOISheetView(applePOIAnnotation: selectedApplePOI,
                                                    draftPlace: draftPlace,
                                                    draftPlacePoiCategory: draftPlacePoiCategory,
                                                    draftPlacePoiColor: draftPlacePoiColor)
    }
    
    // MARK: - callbacks
    func onLongPress(coords: CLLocationCoordinate2D,
                     draftPlace: Binding<PlaceUIModel?>,
                     places: [PlaceUIModel]) {
        preparePlaceFromCoords(coords: coords, draftPlace: draftPlace)
        //viewModel.mapActionBus.performAction(.updateData)
        
        // Show the creation sheet
        presentQuickCreateSheet(draftPlace: draftPlace, places: places)
        
        // Center map on new place
        //mapController.centerOn(coords)
        //centerOn(mapView, coords: coordinates, animated: true, sheetHeight: 400)
    }
    
    func presentQuickCreateSheet(draftPlace: Binding<PlaceUIModel?>, places: [PlaceUIModel]) {
        guard let draftPlaceValue = draftPlace.wrappedValue else {
            //Log.debug("presentQuickCreateSheet called without draftPlace")
            return
        }
        // Check the place isn't the same
        // From address lookup, user could try to create a place he already has
        // In that case we will select and center on it
        if let duplicate = draftDuplicate(draftPlaceValue, places: places) {
            duplicatingPlace = duplicate
            draftPlace.wrappedValue = nil
            isPresentingDuplicatingPlace = true
            return
        }
        // Check also there's not already a different place at this same position
        if let overlapping = draftOverlap(draftPlaceValue, places: places) {
            overlapingPlace = overlapping
            draftPlace.wrappedValue = nil
            isPresentingOverlapingPlace = true
            return
        }
        showQuickCreateSheet = true
    }
    
    func onCameraUpdate(camera: MKMapCamera,
                        region: MKCoordinateRegion,
                        rect: MKMapRect) {
        
        // Update camera
        mapCamera.currentCamera = camera
        mapCamera.currentRegion = region
        
        #if false
        // Can be used to define a specific region in order to fill DropinApp.map.hardStartRegion
        print("CURRENT REGION: ")
        print("MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: \(region.center.latitude), longitude: \(region.center.longitude)), span: MKCoordinateSpan(latitudeDelta: \(region.span.latitudeDelta), longitudeDelta: \(region.span.longitudeDelta))")
        #endif
        
        mapCamera.currentRect = rect
        appContainer.rememberMapRegion(region)

        // Update picker position if needed
        guard pickingAddress else { return }
        let cameraCenter = camera.centerCoordinate
        updatePlacePickerPositions(coords: cameraCenter)
    }

    func interactionStatus() -> PlacesMKMapVCR.InteractionStatus {
        return !pickingAddress ? .all : .none
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
    
    func preparePlaceFromCoords(coords: CLLocationCoordinate2D, draftPlace: Binding<PlaceUIModel?>) {
        let createdPlace = PlaceUIModel(coordinates: coords)
        draftPlace.wrappedValue = createdPlace
    }

    func preparePlaceFromAddress(coords: CLLocationCoordinate2D,
                                 address: String?,
                                 draftPlace: Binding<PlaceUIModel?>){
        let createdPlace = PlaceUIModel(coordinates: coords)
        if let address = address {
            createdPlace.address = address
        }
        draftPlace.wrappedValue = createdPlace
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
    
    func prepareApplePOI(_ poiAnnotation: MKMapFeatureAnnotation) {
        presentApplePOI = true
    }
    
    // MARK: - private
    private func draftDuplicate(_ draftPlace: PlaceUIModel, places: [PlaceUIModel]) -> PlaceUIModel? {
        let draftDomainPlace = PlaceMapper.toDomain(draftPlace)
        return places
            .filter {
                guard $0.isActive else { return false }
                if draftDomainPlace.isIdentical(name: $0.name, coords: $0.coordinates) {
                    return true
                }
                if draftDomainPlace.applePlaceID != nil && draftDomainPlace.applePlaceID == $0.applePlaceID {
                    return true
                }
                return false
            }
            .first
    }

    private func draftOverlap(_ draftPlace: PlaceUIModel, places: [PlaceUIModel]) -> PlaceUIModel? {
        let draftDomainPlace = PlaceMapper.toDomain(draftPlace)
        return places
            .filter {
                guard $0.isActive else { return false }
                // Do not allow overlap if distance is lower than 3 meters
                return draftDomainPlace.coordinates.distance(to: $0.coordinates) <= 3
            }
            .first
    }

    private func updatePlacePickerPositions() {
        updatePlacePickerPositions(coords: mapCamera.currentCamera.centerCoordinate)
    }

    private func updatePlacePickerPositions(coords: CLLocationCoordinate2D) {
        guard pickingAddress else {
            assertionFailure()
            return
        }
        // Compute pickers coordinates
        let sheetHeight = DropinApp.ui.addressPickerSheetHeight
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
        addressPickerCoords = offsetCoords
        addressPickerViewCoords = offsetPoint
        pickedAddress = nil
        fetchAddress()
    }
    
    private func fetchAddress() {
        guard pickingAddress else {
            assertionFailure()
            return
        }
        guard pickedAddress == nil else {
            // Already fetched for this position
            return
        }
        fetchingAddressPicker = true
        addressPickingTask?.cancel()
        addressPickingTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else {
                // The task should only be cancelled by a new fetch request
                // keep the fetching flag = true
                return
            }
            do {
                let address = try await fetchAddress(coords: addressPickerCoords)
                pickedAddress = address
            } catch {
                // Address picker shows a connection if fetch fails
                // TODO: (improvement) error could be provided for specific message
            }
            fetchingAddressPicker = false
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

    @Observable fileprivate class MapCamera {

        // MARK: - Non-observed camera state (written by map delegate — must NOT trigger SwiftUI re-renders)
        @ObservationIgnored public var currentCamera: MKMapCamera = .init()
        @ObservationIgnored public var currentRegion: MKCoordinateRegion = .zero
        @ObservationIgnored public var currentRect: MKMapRect = .null
    }
}
