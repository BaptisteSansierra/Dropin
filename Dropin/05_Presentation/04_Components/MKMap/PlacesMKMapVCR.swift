//
//  PlacesMKMapVCR.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/6/26.
//

import SwiftUI
import UIKit
import MapKit

typealias MapCameraUpdateHandler = (MKMapCamera,
                                    MKCoordinateRegion,
                                    MKMapRect) -> Void

@MainActor
struct PlacesMKMapVCR: UIViewControllerRepresentable {

    struct Configuration {
        enum LaunchPosition {
            case follow
            case region(region: MKCoordinateRegion)
            case none
        }
        
        var scrollEnabled = true
        var zoomEnabled = true
        var rotateEnabled = false
        //var clustering = true
        var showsUserLocation = true
        //var tracksUserAtLaunch = true
        var positionAtLaunch: LaunchPosition = .follow
        //var hidesLabelsWhenZoomedOut = true

        static let interactive = Configuration()                 // main map
        static let preview = Configuration(scrollEnabled: false,
                                           zoomEnabled: false,
                                           showsUserLocation: false,
                                           positionAtLaunch: .region(region: .abbeyRoad
                                            .offset(lat: -0.001)))
        static let browse = Configuration(positionAtLaunch: .none)  // group/tag map ??
    }
    
    @Environment(AppSettings.self) private var appSettings

    @Binding private var selectedPlaceId: UUID?

    private let config: Configuration
    private let mapController: MapController
    private let places: [PlaceUI]
    private let pendingCoordinate: CLLocationCoordinate2D?
    private let bottomInset: CGFloat
    private let mapReloadGen: Int
    //private let onPlaceSelected: ((UUID) -> Void)?
    private let onLongPress: ((CLLocationCoordinate2D) -> Void)?
    private let onMapCameraUpdate: MapCameraUpdateHandler?
    private let isSelectionEnabled: (() -> Bool)
    
    // MARK: Init
    init(config: Configuration,
         mapController: MapController,
         places: [PlaceUI],
         pendingCoordinate: CLLocationCoordinate2D? = nil,
         selectedPlaceId: Binding<UUID?>,
         //onPlaceSelected: ((UUID) -> Void)? = nil,
         onLongPress: ((CLLocationCoordinate2D) -> Void)? = nil,
         onMapCameraUpdate: MapCameraUpdateHandler? = nil,
         isSelectionEnabled: @escaping (() -> Bool),
         mapReloadGen: Int = 0,
         bottomInset: CGFloat = 0) {
        self.config = config
        self.mapController = mapController
        self.places = places
        self.pendingCoordinate = pendingCoordinate
        self._selectedPlaceId = selectedPlaceId
        //self.onPlaceSelected = onPlaceSelected
        self.onLongPress = onLongPress
        self.onMapCameraUpdate = onMapCameraUpdate
        self.isSelectionEnabled = isSelectionEnabled
        self.mapReloadGen = mapReloadGen
        self.bottomInset = bottomInset
    }
    
    func makeUIViewController(context: Context) -> PlacesMKMapVC {
        let viewController = PlacesMKMapVC()
        viewController.coordinator = context.coordinator
        context.coordinator.mapView = viewController.mapView
        
        // Connect map controller
        mapController.connect(context.coordinator)
        
        // Gestures
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        context.coordinator.mapView!.addGestureRecognizer(longPress)
        
        return viewController
    }
    
    func updateUIViewController(_ viewController: PlacesMKMapVC, context: Context) {
        guard let mapView = context.coordinator.mapView else { assertionFailure(); return }
        
        // Update map controller connection
        mapController.connect(context.coordinator)

        // Set additional safe area insets
        viewController.additionalSafeAreaInsets = UIEdgeInsets(top: 0,
                                                               left: 0,
                                                               bottom: bottomInset,
                                                               right: 0)
        //
        // Map style
        //
        applyMapStyle(to: mapView,
                      satellite: appSettings.mapSettings.satellite,
                      hidePointsOfInterest: appSettings.mapSettings.hidePOI)
        
        //
        // Check if settings were updated
        //
        var shouldUpdateAnnotation = false
        if context.coordinator.mapSettings != appSettings.mapSettings {
            let affectsAnns = appSettings.mapSettings.isDiffAffectsAnnotations(context.coordinator.mapSettings)
            context.coordinator.updateSettings(appSettings.mapSettings)
            if affectsAnns { shouldUpdateAnnotation = true }
        }
        
        //
        // Update pendingCoordinate if needed (trigger center on new one)
        //
        if let pendingCoordinate = pendingCoordinate,
           context.coordinator.pendingCoordinate != pendingCoordinate {
            context.coordinator.updatePendingCoordinate(pendingCoordinate)
            updatePendingAnnotations(mapView)
        } else if context.coordinator.pendingCoordinate != nil {
            context.coordinator.resetPendingCoordinate()
            updatePendingAnnotations(mapView)
        }

        
        
//        var updatedPendingCoords = false
//        if let pendingCoordinate = pendingCoordinate {
//            updatedPendingCoords = context.coordinator.centerOnPendingCoordinateIfNeeded(pendingCoordinate)
//        } else {
//            context.coordinator.resetPendingCoordinate()
//        }

        // Reload annotations (places were reloaded from )
        if context.coordinator.lastReloadGen != mapReloadGen ||
            shouldUpdateAnnotation {
            context.coordinator.lastReloadGen = mapReloadGen
            reloadAnnotations(mapView)
        }
        
        // Update annotations — only rebuild when the active place set actually changed
        let activeIds = Set(places.lazy.filter { $0.isActive }.map { $0.id })
        if activeIds != context.coordinator.lastActiveIds {
            context.coordinator.lastActiveIds = activeIds
            updateAnnotations(mapView)
        }
        
        //
        // Update selection
        //
        if mapView.selectedAnnotations.count == 0 && selectedPlaceId != nil  {
            // Select
            let match = mapView.annotations
                .compactMap({ $0 as? MKPlaceAnnotation })
                .filter({ $0.id == selectedPlaceId! })
            if match.count == 1 {
                mapView.selectAnnotation(match[0], animated: true)
            }
        } else if mapView.selectedAnnotations.count > 0 && selectedPlaceId == nil {
            // Deselect
            mapView.deselectAnnotation(mapView.selectedAnnotations[0], animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(config: config,
                    mapSettings: appSettings.mapSettings,
                    onPlaceSelected: { uuid in
                        selectedPlaceId = uuid
                    },
                    onLongPress: onLongPress,
                    onMapCameraUpdate: onMapCameraUpdate,
                    isSelectionEnabled: isSelectionEnabled)
    }
    
    // MARK: private methods
    private func applyMapStyle(to mapView: MKMapView, satellite: Bool, hidePointsOfInterest: Bool) {
        // Map type
        mapView.mapType = satellite ? .hybrid : .standard
        
        // Points of interest filter
        if hidePointsOfInterest {
            mapView.pointOfInterestFilter = MKPointOfInterestFilter(including: [.publicTransport])
        } else {
            mapView.pointOfInterestFilter = .includingAll
        }
        
        // Traffic
        mapView.showsTraffic = false
    }
    
    private func reloadAnnotations(_ mapView: MKMapView) {
        
        /*
        let placeAnnotations = mapView.annotations.compactMap { $0 as? MKPlaceAnnotation }
        for placeAnnotation in placeAnnotations {
            if let newest
            placeAnnotation.place.changeToken
        }
         */
        
        let latestAnnotations = places
            .filter { $0.isActive }
            .map { MKPlaceAnnotation(place: $0) }
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(latestAnnotations)
        
        
        
        
        
        
        // Add pending place
//        if let pendingCoordinate = pendingCoordinate {
//            mapView.addAnnotation(MKTempPlaceAnnotation(coordinate: pendingCoordinate))
//        }
    }
    
    private func updateAnnotations(_ mapView: MKMapView) {
        let activePlaces = places.filter { $0.isActive }
        let current = mapView.annotations.compactMap { $0 as? MKPlaceAnnotation }
        
        let newIds = Set(activePlaces.map { $0.id })
        let currentIds = Set(current.map { $0.id })
        
        // Remove legacy annotations
        let toRemove = current.filter { !newIds.contains($0.id) }
        mapView.removeAnnotations(toRemove)
        
        // Add new annotations
        let toAdd = activePlaces
            .filter { !currentIds.contains($0.id) }
            .map { MKPlaceAnnotation(place: $0) }
        mapView.addAnnotations(toAdd)
        
        // Pending place
//        if let pendingAnnotation = pendingAnnotation(mapView) {
//            mapView.removeAnnotation(pendingAnnotation)
//        }
//        if let pendingCoordinate = pendingCoordinate {
//            mapView.addAnnotation(MKTempPlaceAnnotation(coordinate: pendingCoordinate))
//        }
    }
    
    private func updatePendingAnnotations(_ mapView: MKMapView) {
        // Remove old pending coordinate if needed
        let pendingAnnotations = mapView.annotations.compactMap { $0 as? MKTempPlaceAnnotation }
        if pendingAnnotations.count > 1 {
            assertionFailure("More than one pending annotation found...")
        }
        mapView.removeAnnotations(pendingAnnotations)
        // Add new pending coordinate if needed
        if let pendingCoordinate = pendingCoordinate {
            mapView.addAnnotation(MKTempPlaceAnnotation(coordinate: pendingCoordinate))
        }
    }
    
    private func pendingAnnotation(_ mapView: MKMapView) -> MKTempPlaceAnnotation? {
        let pendingAnnotations = mapView.annotations.compactMap { $0 as? MKTempPlaceAnnotation }
        guard pendingAnnotations.count <= 1 else {
            assertionFailure("More than one pending annotation found...")
            mapView.removeAnnotations(pendingAnnotations)
            return nil
        }
        return pendingAnnotations.first
    }
}

// MARK: Coordinator
extension PlacesMKMapVCR {
    
    @MainActor
    class Coordinator: NSObject {
        
        fileprivate var config: Configuration
        fileprivate var annotationViewFactory: AnnotationViewFactory
        fileprivate var mapSettings: MapSettings
        
        private let onPlaceSelected: ((UUID) -> Void)
        private let onLongPress: ((CLLocationCoordinate2D) -> Void)?
        private let onMapCameraUpdate: MapCameraUpdateHandler?
        private let isSelectionEnabled: (() -> Bool)
        private(set) var pendingCoordinate: CLLocationCoordinate2D? = nil
        
        var lastReloadGen: Int = 0
        weak var mapView: MKMapView?
        
        // Annotation update guard
        var lastActiveIds: Set<UUID> = []
        // Label visibility state
        private var labelsVisible: Bool = true
        
        // MARK: init
        init(config: Configuration,
             mapSettings: MapSettings,
             onPlaceSelected: @escaping ((UUID) -> Void),
             onLongPress: ((CLLocationCoordinate2D) -> Void)?,
             onMapCameraUpdate: MapCameraUpdateHandler?,
             isSelectionEnabled: @escaping (() -> Bool) ) {
            self.config = config
            self.mapSettings = mapSettings
            self.annotationViewFactory = AnnotationViewFactory(mapSettings: mapSettings)
            self.onPlaceSelected = onPlaceSelected
            self.onLongPress = onLongPress
            self.onMapCameraUpdate = onMapCameraUpdate
            self.isSelectionEnabled = isSelectionEnabled
        }
        
        func updateSettings(_ mapSettings: MapSettings) {
            self.mapSettings = mapSettings
            self.annotationViewFactory = AnnotationViewFactory(mapSettings: mapSettings)
        }
        
        // MARK: - gestures
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            /*
             guard !viewModel.pickingAddress else { return }
             guard !viewModel.pickingCoordinates else { return }
             guard gesture.state == .began else { return }
             
             let mapView = gesture.view as! MKMapView
             let point = gesture.location(in: mapView)
             let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
             
             viewModel.preparePlaceFromCoords(coords: coordinates)
             viewModel.mapActionBus.performAction(.updateData)
             
             // Show the creation sheet
             viewModel.showQuickCreateSheet.toggle()
             // Center map on new place
             centerOn(mapView, coords: coordinates, animated: true, sheetHeight: 400)
             */
            
            
            guard let onLongPress = onLongPress else { return }
            // TODO: guard picking
            guard gesture.state == .began else { return }
            
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
            
            onLongPress(coordinates)
        }
        
        func fitAll(animated: Bool) {
            guard let mapView else { return }
            let placeAnnotations = mapView.annotations.compactMap { $0 as? MKPlaceAnnotation }
            guard !placeAnnotations.isEmpty else { return }
            mapView.showAnnotations(placeAnnotations, animated: animated)
        }
        
        func centerOn(coords: CLLocationCoordinate2D,
                      withSheetOffset: Bool,
                      animated: Bool = true) {
            guard let mapView = mapView else { return }
            centerOn(mapView,
                     coords: coords,
                     withSheetOffset: withSheetOffset,
                     animated: true)
        }
        
        func updatePendingCoordinate(_ coords: CLLocationCoordinate2D) {
            guard pendingCoordinate != coords else { return }
            pendingCoordinate = coords
            centerOn(coords: coords,
                     withSheetOffset: true,
                     animated: true)
        }
        
        func resetPendingCoordinate() {
            pendingCoordinate = nil
        }
        
        // MARK: - private methods
        private func centerOn(_ mapView: MKMapView,
                              coords: CLLocationCoordinate2D,
                              withSheetOffset: Bool,
                              animated: Bool = true) {
            
            let sheetHeight: CGFloat? = withSheetOffset ? 400 : nil // FIXME: this value should be provided somehow
            let comfortableSpan: CLLocationDistance = 1_500 // 1500 meters
            
            let bottomPadding = sheetHeight ?? 0
            
            // -- Case 1: zoom in needed (current view is wider than comfortable) --
            let metersPerMP   = MKMetersPerMapPointAtLatitude(coords.latitude)
            let comfortable   = comfortableSpan / metersPerMP
            let current       = mapView.visibleMapRect.size.width
            
            if current > comfortable {
                let p = MKMapPoint(coords)
                let rect = MKMapRect(x: p.x - comfortable/2,
                                     y: p.y - comfortable/2,
                                     width: comfortable,
                                     height: comfortable)
                mapView.setVisibleMapRect(
                    rect,
                    edgePadding: UIEdgeInsets(top: 0, left: 0,
                                              bottom: bottomPadding, right: 0),
                    animated: animated)
                return
            }
            // else: already close enough — fall through to pan-only
            
            // -- Case 2: pan only (preserve zoom), apply sheet offset --
            guard bottomPadding > 0 else {
                mapView.setCenter(coords, animated: animated)
                return
            }
            let upwardShift = bottomPadding / 2
            let pinNow      = mapView.convert(coords, toPointTo: mapView)
            let newCenterPt = CGPoint(x: pinNow.x, y: pinNow.y + upwardShift)
            let newCenter   = mapView.convert(newCenterPt, toCoordinateFrom: mapView)
            mapView.setCenter(newCenter, animated: animated)
        }
    }
}
    // MARK: - MKMapViewDelegate
    extension PlacesMKMapVCR.Coordinator: MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            annotationViewFactory.view(for: annotation, in: mapView)
        }
        
        func mapView(_ mapView: MKMapView, shouldSelect view: MKAnnotationView) -> Bool {
            isSelectionEnabled()
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard isSelectionEnabled() else { return }

            if let cluster = view.annotation as? MKClusterAnnotation {
                // Zoom into cluster
                mapView.showAnnotations(cluster.memberAnnotations, animated: true)
            } else if let placeAnnotation = view.annotation as? MKPlaceAnnotation {
                /*
                guard !viewModel.pickingAddress else { return }
                guard !viewModel.pickingCoordinates else { return }

                view.isSelected = true
                
                let defaultSheetDetent: CGFloat = 400 // FIXME: this value should be provided somehow
                centerOn(mapView,
                         coords: placeAnnotation.coordinate,
                         animated: true,
                         sheetHeight: defaultSheetDetent)
                //viewModel.selectPlace(placeAnnotation.id)
                selectedPlaceId(placeAnnotation.id)
                 */
                
                //guard let onPlaceSelected = onPlaceSelected else { return }
                // TODO: guard picking
                view.isSelected = true
                
                centerOn(mapView,
                         coords: placeAnnotation.coordinate,
                         withSheetOffset: true,
                         animated: true)

                onPlaceSelected(placeAnnotation.id)
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            guard let _ = view.annotation as? MKPlaceAnnotation else { return }
            view.isSelected = false
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            guard let onMapCameraUpdate = onMapCameraUpdate else { return }
            
            /*
            let project: (CGPoint) -> CLLocationCoordinate2D = { point in
                mapView.convert(point, toCoordinateFrom: mapView)
            }

            let unproject: (CLLocationCoordinate2D) -> CGPoint = { coords in
                mapView.convert(coords, toPointTo: mapView)
            }
             */
            
            onMapCameraUpdate(mapView.camera,
                              mapView.region,
                              mapView.visibleMapRect)
        }
    }





// MARK: - MapViewController
class PlacesMKMapVC: UIViewController {

    var mapView: MKMapView
    fileprivate weak var coordinator: PlacesMKMapVCR.Coordinator?
    fileprivate weak var appSettings: AppSettings?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.mapView = MKMapView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    convenience init(coordinator: PlacesMKMapVCR.Coordinator) {
        self.init(nibName: nil, bundle: nil)
        self.coordinator = coordinator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let coordinator = coordinator else { fatalError("undefined coordinator") }
        
        mapView.delegate = coordinator
        
        mapView.showsUserLocation = coordinator.config.showsUserLocation
        mapView.mapType = .standard
        mapView.isScrollEnabled = coordinator.config.scrollEnabled
        mapView.isZoomEnabled = coordinator.config.zoomEnabled
        mapView.isRotateEnabled = coordinator.config.rotateEnabled
        mapView.isPitchEnabled = false
        switch coordinator.config.positionAtLaunch {
            case .follow:
                mapView.userTrackingMode = .follow
            case .region(let region):
                mapView.userTrackingMode = .none
                mapView.setRegion(region, animated: false)
            case .none:
                mapView.userTrackingMode = .none
        }

        coordinator.annotationViewFactory.registerViews(for: mapView)

        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}





#if DEBUG

struct MockPlacesMKMapVCR: View {
    //var mock: MockContainer
    @State var places: [PlaceUI]
    @State var settings: AppSettings
    @State var clustering: Bool = true
    @State var selectedPlaceId: UUID?

    var body: some View {
        
        TabView {

            VStack {
                
                Button {
                    if selectedPlaceId == nil {
                        selectedPlaceId = places.randomElement()!.id
                    } else {
                        selectedPlaceId = nil
                    }
                } label: {
                    if selectedPlaceId == nil {
                        Text("Select random")
                    } else {
                        Text("UnSelect")
                    }
                }

                
                // INTERACTIVE TAB
                PlacesMKMapVCR(config: .interactive,
                               mapController: MapController(),
                               places: places,
                               selectedPlaceId: $selectedPlaceId,
                               //onPlaceSelected: { uuid in print("SELECTED PLACE \(uuid)") },
                               onLongPress: { coords in print("LONG PRESSED \(coords)") },
                               onMapCameraUpdate: onMapCameraUpdate,
                               isSelectionEnabled: { return true },
                               mapReloadGen: 0,
                               bottomInset: 0)
            }
            .tabItem {
                Label("Interactive", systemImage: "map")
            }

            // PREVIEW(SETTINGS) TAB
            VStack {
                PlacesMKMapVCR(config: PlacesMKMapVCR.Configuration(scrollEnabled: false,
                                                                    zoomEnabled: false,
                                                                    showsUserLocation: false,
                                                                    positionAtLaunch: .region(region: .barcelona
                                                                        .zoom(0.2))),
                               mapController: MapController(),
                               places: places,
                               pendingCoordinate: .barcelona.offset(x: 0.02, y: -0.02),
                               selectedPlaceId: Binding<UUID?>.constant(nil),
                               isSelectionEnabled: { return false },
                               mapReloadGen: 0,
                               bottomInset: 0)
                Toggle(isOn: $settings.mapSettings.clustering) {
                    Text("Clustering")
                }
            }
            .padding(.horizontal)
            .tabItem {
                Label("Interactive", systemImage: "gear")
            }

        }
        .environment(settings)
    }
    
    private func onMapCameraUpdate(camera: MKMapCamera,
                                   region: MKCoordinateRegion,
                                   rect: MKMapRect) {
        //print("UP CAM")
    }
    
    init() {
        //let mock = MockContainer()
        //self.mock = mock
        let place1 = PlaceUI(coordinates: .barcelona)
        place1.group = GroupUI(color: "AE271A")
        let place2 = PlaceUI(coordinates: .barcelona.offset(x: 0.01))
        let place3 = PlaceUI(coordinates: .barcelona.offset(y: 0.01))
        let place4 = PlaceUI(coordinates: .barcelona.offset(x: 0.02, y: -0.02))
        let place5 = PlaceUI(coordinates: .barcelona.offset(x: 0.0201, y: -0.0201))
        self.places = [place1, place2, place3, place4, place5]
        
        settings = AppSettings()
        settings.mapSettings.satellite = false
        settings.mapSettings.pinStyle = .rounded
    }
}

#Preview {
    NavigationStack {
        MockPlacesMKMapVCR()
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#endif
