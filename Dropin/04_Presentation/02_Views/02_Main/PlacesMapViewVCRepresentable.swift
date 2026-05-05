//
//  PlacesMapViewVCRepresentable.swift
//  Dropin
//
//  Created by baptiste sansierra on 25/3/26.
//

import SwiftUI
import UIKit
import MapKit

@MainActor
struct PlacesMapViewVCRepresentable: UIViewControllerRepresentable {
    
    // MARK: States & Bindings
    @Bindable private var viewModel: PlacesMapViewModel
    @Binding private var selectedPlaceId: UUID?
    @State private var tmpPlaceAnnotation: MKTempPlaceAnnotation?
    @Environment(AppSettings.self) private var appSettings

    private var places: [PlaceUI]
    //var topInset: CGFloat = 0
    var bottomInset: CGFloat = 0

    // MARK: Init
    init(viewModel: PlacesMapViewModel,
         //places: Binding<[PlaceUI]>,
         places: [PlaceUI],
         selectedPlaceId: Binding<UUID?>,
         //topInset: CGFloat,
         bottomInset: CGFloat) {
        self.viewModel = viewModel
        //self._places = places
        self.places = places
        self._selectedPlaceId = selectedPlaceId
        self.bottomInset = bottomInset
        //self.topInset = topInset
    }
        
    func makeUIViewController(context: Context) -> PlacesMapViewController {
        let viewController = PlacesMapViewController()
        viewController.coordinator = context.coordinator
        context.coordinator.mapView = viewController.mapView
        
        // Gestures
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        context.coordinator.mapView!.addGestureRecognizer(longPress)

        return viewController
    }
    
    func updateUIViewController(_ viewController: PlacesMapViewController, context: Context) {
        guard let mapView = context.coordinator.mapView else { assertionFailure(); return }
        // Set additional safe area insets
        viewController.additionalSafeAreaInsets = UIEdgeInsets(top: 0,
                                                               left: 0,
                                                               bottom: bottomInset,
                                                               right: 0)

        // Map style
        applyMapStyle(to: mapView,
                      satellite: appSettings.satellite,
                      hidePointsOfInterest: appSettings.hidePOI)

        // Update annotations — only rebuild when the active place set actually changed
        let activeIds = Set(places.lazy.filter { $0.isActive }.map { $0.id })
        if activeIds != context.coordinator.lastActiveIds {
            context.coordinator.lastActiveIds = activeIds
            updateAnnotations(mapView)
        }

        // Handle actions
        if let action = viewModel.mapActionBus.currentAction {
            // Reset action once it's catched
            viewModel.mapActionBus.currentAction = nil
            executeAction(action, on: mapView, context: context)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel,
                    appSettings: appSettings,
                    selectedPlaceId: { uuid in
            self.selectedPlaceId = uuid
        })
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
    
    private func executeAction(_ action: PlacesMapViewModel.MapActionBus.MapAction, on mapView: MKMapView, context: Context) {
        switch action {
            case .clearSelection:
                for annotation in mapView.selectedAnnotations {
                    mapView.deselectAnnotation(annotation, animated: true)
                }
            case .centerOnCoords(let coords, let animated, let sheetHeight):
                context.coordinator.centerOn(mapView, coords: coords, animated: animated, sheetHeight: sheetHeight)
            case .reloadData:
                reloadAnnotations(mapView)
                context.coordinator.lastActiveIds = []
            case .updateData:
                updateAnnotations(mapView)
            case .updatePlacePickerPositions:
                context.coordinator.updatePlacePickerPositions(mapView)
            case .selectPlace(let placeId):
                guard let ann = mapView.annotations
                    .compactMap({ $0 as? MKPlaceAnnotation })
                    .first(where: { $0.place.id == placeId }) else {
                    return
                }
                mapView.selectAnnotation(ann, animated: true)
        }
    }
    
    private func reloadAnnotations(_ mapView: MKMapView) {
        let newAnnotations = places
            .filter { $0.isActive }
            .map { MKPlaceAnnotation(place: $0) }
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(newAnnotations)

        // Add temporary place
        if let tmpPlace = viewModel.tmpPlace {
            mapView.addAnnotation(MKTempPlaceAnnotation(coordinate: tmpPlace.coordinates))
        }
    }
    
    private func updateAnnotations(_ mapView: MKMapView) {
        let activePlaces = places.filter { $0.isActive }
        let current = mapView.annotations.compactMap { $0 as? MKPlaceAnnotation }

        let newIds = Set(activePlaces.map { $0.id })
        let currentIds = Set(current.map { $0.id })

        let toRemove = current.filter { !newIds.contains($0.id) }
        mapView.removeAnnotations(toRemove)

        let toAdd = activePlaces
            .filter { !currentIds.contains($0.id) }
            .map { MKPlaceAnnotation(place: $0) }
        mapView.addAnnotations(toAdd)

        // Temporary place
        mapView.removeAnnotations(mapView.annotations.compactMap { $0 as? MKTempPlaceAnnotation })
        if let tmpPlace = viewModel.tmpPlace {
            mapView.addAnnotation(MKTempPlaceAnnotation(coordinate: tmpPlace.coordinates))
        }
    }
}

// MARK: Coordinator
extension PlacesMapViewVCRepresentable {

    @MainActor
    class Coordinator: NSObject, MKMapViewDelegate {

        private let viewModel: PlacesMapViewModel
        private var addressPickingTask: Task<Void, Never>? = nil
        private var selectedPlaceId: (UUID?) -> Void

        fileprivate var annotationViewFactory: AnnotationViewFactory

        weak var mapView: MKMapView?

        // Annotation update guard
        var lastActiveIds: Set<UUID> = []
        // Label visibility state
        private var labelsVisible: Bool = true

        // MARK: init
        init(viewModel: PlacesMapViewModel,
             appSettings: AppSettings,
             selectedPlaceId: @escaping (UUID?) -> Void) {
            self.viewModel = viewModel
            self.annotationViewFactory = AnnotationViewFactory(appSettings: appSettings)
            self.selectedPlaceId = selectedPlaceId
        }
        
        // MARK: - gestures
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
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
        }
        
        // MARK: - MKMapViewDelegate
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            annotationViewFactory.view(for: annotation, in: mapView)
        }
        
        func mapView(_ mapView: MKMapView, shouldSelect view: MKAnnotationView) -> Bool {
            guard !viewModel.pickingAddress else { return false }
            guard !viewModel.pickingCoordinates else { return false }
            return true
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let cluster = view.annotation as? MKClusterAnnotation {
                // Zoom into cluster
                mapView.showAnnotations(cluster.memberAnnotations, animated: true)
            } else if let placeAnnotation = view.annotation as? MKPlaceAnnotation {
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
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            guard let _ = view.annotation as? MKPlaceAnnotation else { return }
            view.isSelected = false
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            viewModel.mapSettings.currentCamera = mapView.camera
            viewModel.mapSettings.currentRegion = mapView.region
            viewModel.mapSettings.currentRect = mapView.visibleMapRect

            // Hide labels when zoomed far out — only update views when crossing the threshold
            let shouldShowLabels = mapView.camera.altitude < DropinApp.ui.mapLabelHideAltitude
            if shouldShowLabels != labelsVisible {
                labelsVisible = shouldShowLabels
                for annotation in mapView.annotations {
                    (mapView.view(for: annotation) as? HostingAnnotationView)?.showLabel = shouldShowLabels
                }
            }

            if viewModel.pickingAddress || viewModel.pickingCoordinates {
                updatePlacePickerPositions(mapView)
            }
        }
        
        // MARK: - private methods
        fileprivate func updatePlacePickerPositions(_ mapView: MKMapView) {
            guard viewModel.pickingAddress || viewModel.pickingCoordinates else {
                assertionFailure()
                return
            }
            // Compute pickers coordinates
            let sheetHeight = viewModel.pickingAddress ? DropinApp.ui.addressPickerSheetHeight : DropinApp.ui.coordinatesPickerSheetHeight
            let offset: CGFloat = (sheetHeight - DropinApp.ui.mainTabBarHeight) * -0.5

            let centerPoint = mapView.convert(mapView.camera.centerCoordinate, toPointTo: mapView)
            let offsetPoint = CGPoint(x: centerPoint.x, y: centerPoint.y + offset)
            let offsetCoords = mapView.convert(offsetPoint, toCoordinateFrom: mapView)
            
            if viewModel.pickingAddress {
                viewModel.addressPickerCoords = offsetCoords
                viewModel.addressPickerViewCoords = offsetPoint
            } else {
                viewModel.coordinatesPickerCoords = offsetCoords
                viewModel.coordinatesPickerViewCoords = offsetPoint
            }
            
            viewModel.pickedAddress = nil
            fetchAddress()
        }
        
        fileprivate func centerOn(_ mapView: MKMapView,
                                  coords: CLLocationCoordinate2D,
                                  animated: Bool = true,
                                  sheetHeight: CGFloat? = nil) {
            guard let sheetHeight = sheetHeight else {
                // Simple center
                mapView.setCenter(coords, animated: animated)
                return
            }
            // First move on the target latitude so we're getting correct screen/map delta correlation
            mapView.setCenter(coords, animated: animated)
            // Get the screen point for the map center point
            let centerPoint = mapView.convert(mapView.camera.centerCoordinate, toPointTo: mapView)
            // Offset the point considering sheet height + tabBar height
            // FIXME: can we improve by using map size (+ insets) ?
            let offset: CGFloat = (sheetHeight - DropinApp.ui.mainTabBarHeight) * -0.5
            let offsetPoint = CGPoint(x: centerPoint.x, y: centerPoint.y - offset)
            // Get the offset map point
            let offsetCoords = mapView.convert(offsetPoint, toCoordinateFrom: mapView)
            mapView.setCenter(offsetCoords, animated: animated)
        }
                
        private func fetchAddress() {
            guard viewModel.pickingAddress || viewModel.pickingCoordinates else {
                assertionFailure()
                return
            }
            guard viewModel.pickedAddress == nil else {
                // Already fetched for this position
                return
            }
            let coords = viewModel.pickingAddress ? viewModel.addressPickerCoords : viewModel.coordinatesPickerCoords
            addressPickingTask?.cancel()
            addressPickingTask = Task {
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else {
                    return
                }
                do {
                    let address = try await viewModel.fetchAddress(coords: coords)
                    viewModel.pickedAddress = address
                } catch {
                    // TODO: handle error
                    return
                }
            }
        }
    }
}

// MARK: - MapViewController
class PlacesMapViewController: UIViewController {

    var mapView: MKMapView
    fileprivate weak var coordinator: PlacesMapViewVCRepresentable.Coordinator?
    fileprivate weak var appSettings: AppSettings?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.mapView = MKMapView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    convenience init(coordinator: PlacesMapViewVCRepresentable.Coordinator) {
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
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow // Track user location at launch
        mapView.mapType = .standard
        
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
