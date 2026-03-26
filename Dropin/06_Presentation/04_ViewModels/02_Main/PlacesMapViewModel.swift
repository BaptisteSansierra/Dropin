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
    
    private enum CreationMode {
        case coords
        case undefined
    }
    
    #if true
    /// Used to communicate from ViewModel to ViewRepresentable
    enum MapAction: Equatable {
        case clearSelection
        case centerOnCoords(coords: CLLocationCoordinate2D, animated: Bool = true, sheetHeight: CGFloat? = nil)
        case reloadData
        case updateData
        case updatePlacePickerPositions
        case selectPlace(id: UUID)
//        case fitAllPlaces
    }
    var currentAction: MapAction?
    
    func performAction(_ action: MapAction) {
        currentAction = action
    }
    #endif
    
    func clearSelection() {
        selectedPlaceId = nil
        performAction(.clearSelection)
    }
    func centerOnUser() {
        guard let coords = locationManager.lastKnownLocation else { return }
        performAction(.centerOnCoords(coords: coords))
    }
    func centerOnCoords(_ coords: CLLocationCoordinate2D, sheetHeight: CGFloat? = nil) {
        performAction(.centerOnCoords(coords: coords, sheetHeight: sheetHeight))
    }
    func reloadMapData() {
        performAction(.reloadData)
    }
    func manualSelectPlace(_ id: UUID) {
        performAction(.selectPlace(id: id))
    }


    
    
    // UI constants
    //var addressSheetHeight: CGFloat = 350
    //var coordinatesSheetHeight: CGFloat = 400

    // Alerts toggles
    var showAuthLocAlert = false
    var showQuickCreateSheet = false

    

    // MARK: Properties
    private(set) var coordinator: MainCoordinator

    var locationManager: LocationManager

    //var places: [PlaceUI] = [PlaceUI]()
    var tmpPlace: PlaceUI? = nil   // Used for creating a new place

    var pickingAddress: Bool = false {
        didSet {
            guard pickingAddress else { return }
            performAction(.updatePlacePickerPositions)
        }
    }
    var pickingCoordinates: Bool = false {
        didSet {
            guard pickingCoordinates else { return }
            performAction(.updatePlacePickerPositions)
        }
    }
    var pickedAddress: String? = nil   // Used for creating a new place by address picking
    var addressPickerCoords: CLLocationCoordinate2D = .zero
    var addressPickerViewCoords: CGPoint = .zero
    var coordinatesPickerCoords: CLLocationCoordinate2D = .zero
    var coordinatesPickerViewCoords: CGPoint = .zero
    
    func coordinatesPickerUpdate(_ newCoords: CLLocationCoordinate2D) {
        performAction(.centerOnCoords(coords: newCoords,
                                      animated: false,
                                      sheetHeight: DropinApp.ui.coordinatesPickerSheetHeight))
        Task {
            try? await Task.sleep(for: .seconds(0.1))
            performAction(.updatePlacePickerPositions)
        }
    }
    
    

    /// `selectedPlaceId` is defined when a place annotation is selected on the map, toggle the corresponding sheet
    var selectedPlaceId: UUID?
    var selectedClusterId: UUID?
    
    
/*
    var selectedPlaceId: PlaceID? {
        didSet {
//            guard let selectedPlaceId = selectedPlaceId else { return }
//            if places.firstIndex(where: { $0.id == selectedPlaceId.id }) == nil {
//                assertionFailure("no place found related to selectedPlaceId: \(selectedPlaceId)")
//                self.selectedPlaceId = nil
//            }
        }
    }
 */
    
    
    var detailSheetDetent: PresentationDetent = .medium

    var mapSettings: MapSettings
    
    // Clustering
    /*
    var mapItems: [MapDisplayItem] = [MapDisplayItem]()
    var visiblePlaces = [PlaceUI]()
    var clusteringEnabled = true
    
    var buckets = [Bucket]()
    var debugDisplayBuckets = false
     */
    
    
//    var mapPlaceItems: [MapDisplayPlaceItem] = [MapDisplayPlaceItem]()
//    var mapClusterItems: [MapDisplayClusterItem] = [MapDisplayClusterItem]()

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let getPlaces: GetPlaces
    @ObservationIgnored private let createPlace: CreatePlace
    @ObservationIgnored private var creationMode: CreationMode = .undefined  // TODO: to be used ?
    //@ObservationIgnored private let deletePlace: DeletePlace

    
    
    
    //let clusterManager: ClusterManager<ExampleAnnotation>
    //var mapSize: CGSize = .zero
//    var dataSource: MapDataSource
    
    
    
    
    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         locationManager: LocationManager,
         getPlaces: GetPlaces,
         createPlace: CreatePlace) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
        self.getPlaces = getPlaces
        self.createPlace = createPlace
        self.mapSettings = MapSettings()

        //dataSource = MapDataSource()
    }
    
    // MARK: Navigation
    func pushLookupPlacesView() {
        coordinator.pushLookupPlacesView()
    }

    #if false
    func pushDropAPinView() {
        coordinator.pushDropAPinView()
    }
    #endif
    
    // MARK: - UI child
    func createPlaceCreateQuickView() -> PlaceCreateQuickView {
        guard let tmpPlace = tmpPlace else {
            fatalError("temporary place undefined")
        }
        return appContainer.createPlaceCreateQuickView(place: tmpPlace)
    }
        
    func createPlaceSheetView(place: Binding<PlaceUI>, detend: Binding<PresentationDetent>) -> PlaceSheetView {
        return appContainer.createPlaceSheetView(place: place, detent: detend)
    }

    // MARK: - Use cases
    func loadPlaces() async throws -> [PlaceUI] {
        let domainPlaces = try await getPlaces.execute()
        //domainPlaces = domainPlaces.filter { !$0.databaseDeleted }
        let places = domainPlaces.map { PlaceMapper.toUI($0) }
        // check selectedPlaceId is nil or valid after loading places
        if let selectedPlaceId = selectedPlaceId {
            if places.firstIndex(where: { $0.id == selectedPlaceId }) == nil {
                self.selectedPlaceId = nil
            }
        }
        return places
    }

    // MARK: - Actions
    func selectPlace(_ id: UUID) {
        selectedPlaceId = id
    }

    /*
    func fillDataSource(places: [PlaceUI]) async {
        await dataSource.loadPlaces(places)
    }

    func updateDataSource(places: [PlaceUI]) async {
        await dataSource.updatePlaces(places)
    }
     */

    func preparePlaceFromCoords(coords: CLLocationCoordinate2D) -> PlaceUI {
        creationMode = .coords
        let createdPlace = PlaceUI(coordinates: coords)
        tmpPlace = createdPlace
        return createdPlace
    }

    func preparePlaceFromAddress(coords: CLLocationCoordinate2D,
                                 address: String?) -> PlaceUI {
        creationMode = .coords
        let createdPlace = PlaceUI(coordinates: coords)
        if let address = address {
            createdPlace.address = address
        }
        tmpPlace = createdPlace
        return createdPlace
    }

    func discardCreation() {
        reset()
    }

    func fetchAddress(coords: CLLocationCoordinate2D) async throws -> String {
        return try await LocationManager.lookUpAddress(coords: coords)
    }

    // MARK: - private
    private func reset() {
        tmpPlace = nil
        //buildingPlace = false
        creationMode = .undefined
        
        performAction(.updateData)
    }
}




// TODO: move this

/// MapSettings owns the main map display settings values
@MainActor
@Observable class MapSettings {
    
    // MARK: - Computed properties
    /*
    var selectedMapStyle: MapStyle {
        if satellite {
            return .hybrid(elevation: .flat,
                           pointsOfInterest: hidePointsOfInterest ? PointOfInterestCategories.including([MKPointOfInterestCategory.publicTransport]) : .all,
                           showsTraffic: false)
        }
        return .standard(elevation: .flat,
                         pointsOfInterest: hidePointsOfInterest ? PointOfInterestCategories.including([MKPointOfInterestCategory.publicTransport]) : .all,
                         showsTraffic: false)
    }
     */
    
    // MARK: - Published properties
    /// `position` can be used to set the main map camera position
    var position: MapCameraPosition = .automatic


    
    /// The current map camera.
    public var currentMKCamera: MKMapCamera = .init()
    public var currentCamera: MapCamera = .init(centerCoordinate: .zero, distance: 0) // to be removed
    /// A map region approximating the view of the map's camera.
    public var currentRegion: MKCoordinateRegion = .zero
    /// A map rect approximating the view of the map's camera.
    public var currentRect: MKMapRect = .null

    /*
    /// `currentCameraCenter` can be used to get the main map current camera center
    var currentCameraCenter = CLLocationCoordinate2D()
    /// `currentCameraDistance` can be used to get the main map current camera distance
    var currentCameraDistance: Double = 0
    /// `currentRegionSpan` can be used to get the main map current region span distance
    var currentRegionSpan = MKCoordinateSpan()
    */
    
    
    /// `hidePointsOfInterest` show/hide the POI in the main map
    var hidePointsOfInterest: Bool = true {
        didSet {
            saveSettings()
        }
    }
    /// `satellite` enable/disable the satellite view in the main map
    var satellite: Bool = false {
        didSet {
            saveSettings()
        }
    }
    /// `settingsShown` show/hide the settings menu in the main map
    var settingsShown: Bool = false
    
    // MARK: - Init
    init() {
        loadSettings()
    }
    
    // MARK: - private methods
    private func loadSettings() {
        let ud = UserDefaults.standard
        // Hide Points Of Interest
        if let v = ud.value(forKey: DropinApp.userDefaultsKeys.mapHidePointsOfInterest) as? Bool {
            hidePointsOfInterest = v
        } else {
            ud.set(hidePointsOfInterest, forKey: DropinApp.userDefaultsKeys.mapHidePointsOfInterest)
        }
        // Satellite
        if let v = ud.value(forKey: DropinApp.userDefaultsKeys.mapSatellite) as? Bool {
            satellite = v
        } else {
            ud.set(satellite, forKey: DropinApp.userDefaultsKeys.mapSatellite)
        }
    }
    
    private func saveSettings() {
        let ud = UserDefaults.standard
        ud.set(hidePointsOfInterest, forKey: DropinApp.userDefaultsKeys.mapHidePointsOfInterest)
        ud.set(satellite, forKey: DropinApp.userDefaultsKeys.mapSatellite)
    }
}
