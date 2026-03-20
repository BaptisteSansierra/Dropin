//
//  PlacesMapViewRepresentable.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/3/26.
//

import SwiftUI
import MapKit

@MainActor
struct PlacesMapViewRepresentable: UIViewRepresentable {

    // MARK: States & Bindings
    @Bindable private var viewModel: PlacesMapViewModel
    @Binding private var places: [PlaceUI]
    @State private var tmpPlaceAnnotation: MKTempPlaceAnnotation?
    
    // MARK: Init
    init(viewModel: PlacesMapViewModel, places: Binding<[PlaceUI]>) {
        self.viewModel = viewModel
        self._places = places
    }

    // MARK: UIViewRepresentable
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow // Track user location at launch
        mapView.mapType = .standard
        
        AnnotationViewFactory.registerViews(for: mapView)
                
        // Gestures
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        mapView.addGestureRecognizer(longPress)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        
        // 0. Map style
        applyMapStyle(to: mapView,
                      satellite: viewModel.mapSettings.satellite,
                      hidePointsOfInterest: viewModel.mapSettings.hidePointsOfInterest)
        
        // 1. Update region (only if changed)
        if !mapView.region.isApproximatelyEqual(to: viewModel.mapSettings.currentRegion) {
            mapView.setRegion(viewModel.mapSettings.currentRegion, animated: true)
        }
        
        // 2. Update annotations
        
        // Update region (only if changed to avoid loops)
        if !mapView.region.isApproximatelyEqual(to: viewModel.mapSettings.currentRegion) {
            mapView.setRegion(viewModel.mapSettings.currentRegion, animated: true)
        }
        
        // Update annotations
        updateAnnotations(mapView)
        
        // 3. Handle actions
        if let action = viewModel.currentAction {
            // Reset action once it's catched
            viewModel.currentAction = nil
            executeAction(action, on: mapView, context: context)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
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
    
    private func executeAction(_ action: PlacesMapViewModel.MapAction, on mapView: MKMapView, context: Context) {
        switch action {
            case .clearSelection:
                for annotation in mapView.selectedAnnotations {
                    mapView.deselectAnnotation(annotation, animated: true)
                }
            case .centerOnCoords(let coords, let animated, let sheetHeight):
                context.coordinator.centerOn(mapView, coords: coords, animated: animated, sheetHeight: sheetHeight)
            case .reloadData:
                reloadAnnotations(mapView)
            case .updateData:
                updateAnnotations(mapView)
            case .updateAddressPickerPositions:
                context.coordinator.updateAddressPickerPositions(mapView)
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
        let newAnnotations = places
            .filter { $0.isActive }
            .map { MKPlaceAnnotation(place: $0) }

        let current = mapView.annotations.compactMap { $0 as? MKPlaceAnnotation }
        
        // Remove deleted annotations
        let toRemove = current.filter { currentAnnotation in
            !newAnnotations.contains { $0.id == currentAnnotation.id }
        }
        mapView.removeAnnotations(toRemove)
        
        // Add new annotations
        let toAdd = newAnnotations.filter { newAnnotation in
            !current.contains { $0.id == newAnnotation.id }
        }
        mapView.addAnnotations(toAdd)

        // Add / remove temporary place
        let tmps = mapView.annotations.compactMap { $0 as? MKTempPlaceAnnotation }
        mapView.removeAnnotations(tmps)
        if let tmpPlace = viewModel.tmpPlace {
            mapView.addAnnotation(MKTempPlaceAnnotation(coordinate: tmpPlace.coordinates))
        }
    }
}

// MARK: Coordinator
extension PlacesMapViewRepresentable {

    @MainActor
    class Coordinator: NSObject, MKMapViewDelegate {
        
        private let viewModel: PlacesMapViewModel
        
        // MARK: init
        init(viewModel: PlacesMapViewModel) {
            self.viewModel = viewModel
        }
        
        // MARK: - gestures
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard !viewModel.pickingAddress else { return }
            guard !viewModel.pickingCoordinates else { return }
            guard gesture.state == .began else { return }
            
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
            
            _ = viewModel.preparePlaceFromCoords(coords: coordinates)
            viewModel.performAction(.updateData)
            
            // Show the creation sheet
            viewModel.showQuickCreateSheet.toggle()
            // Center map on new place
            centerOn(mapView, coords: coordinates, animated: true, sheetHeight: 400)
        }
        
        // MARK: - MKMapViewDelegate
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            AnnotationViewFactory.view(for: annotation, in: mapView)
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
                
                view.isSelected = true
                
                let defaultSheetDetent: CGFloat = 400 // FIXME: this value should be provided somehow
                centerOn(mapView,
                         coords: placeAnnotation.coordinate,
                         animated: true,
                         sheetHeight: defaultSheetDetent)
                viewModel.selectPlace(placeAnnotation.id)
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            guard let _ = view.annotation as? MKPlaceAnnotation else { return }
            view.isSelected = false
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            // Update ViewModel when user pans/zooms
            viewModel.mapSettings.currentMKCamera = mapView.camera
            viewModel.mapSettings.currentRegion = mapView.region
            viewModel.mapSettings.currentRect = mapView.visibleMapRect
            
            if viewModel.pickingAddress || viewModel.pickingCoordinates {
                updateAddressPickerPositions(mapView)
            }
        }
        
        // MARK: - private methods
        fileprivate func updateAddressPickerPositions(_ mapView: MKMapView) {
            // Compute pickers coordinates
            let sheetHeight = viewModel.pickingAddress ? viewModel.addressSheetHeight : viewModel.coordinatesSheetHeight
            let offset: CGFloat = (sheetHeight - DropinApp.ui.mainTabBarHeight) * -0.5

            let centerPoint = mapView.convert(mapView.camera.centerCoordinate, toPointTo: mapView)
            let offsetPoint = CGPoint(x: centerPoint.x, y: centerPoint.y + offset)
            let offsetCoords = mapView.convert(offsetPoint, toCoordinateFrom: mapView)
            
            viewModel.addressPickerCoords = offsetCoords
            viewModel.addressPickerViewCoords = offsetPoint
            viewModel.pickedAddress = nil
            
            fetchAddress()
        }
        
        
        private var addressPickingTask: Task<Void, Never>? = nil
        
        private func fetchAddress() {
            guard viewModel.pickedAddress == nil else {
                // Already fetched for this position
                return
            }
            addressPickingTask?.cancel()
            addressPickingTask = Task {
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else {
                    return
                }
                do {
                    let address = try await viewModel.fetchAddress(coords: viewModel.addressPickerCoords)
                    viewModel.pickedAddress = address
                } catch {
                    // TODO: handle error
                    return
                }
            }
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
            let fraction = sheetHeight / UIScreen.main.bounds.size.height
            let latitudeDeltaOverSheet = mapView.region.span.latitudeDelta * (1 - fraction)
            let offset = mapView.region.span.latitudeDelta * 0.5 - latitudeDeltaOverSheet * 0.5
            // Offset the coords so location is visible on the map despite the sheet appearing
            let coords = CLLocationCoordinate2D(latitude: coords.latitude - offset,
                                                longitude: coords.longitude)
            mapView.setCenter(coords, animated: animated)
        }
    }
}
