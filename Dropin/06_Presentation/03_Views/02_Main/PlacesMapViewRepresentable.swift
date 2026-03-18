//
//  PlacesMapViewRepresentable.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/3/26.
//
#if false

import SwiftUI
import MapKit

@MainActor
class MKPlaceAnnotation: NSObject, MKAnnotation {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let color: UIColor
    let icon: UIImage?
    let place: PlaceUI  // Backreference
    
    init(place: PlaceUI) {
        self.id = place.id
        self.coordinate = place.coordinates
        self.title = place.name
        self.subtitle = place.address
        
        // Convert SwiftUI Color → UIColor
        self.color = UIColor(place.group?.color ?? .gray)
        
        // Convert Icon → UIImage
        if let iconSource = place.icon {
            self.icon = iconSource.uiImage  // You need this conversion
        } else {
            self.icon = nil
        }
        
        self.place = place
        super.init()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PlaceAnnotation else { return false }
        return id == other.id
    }
    
    override var hash: Int {
        id.hashValue
    }
}


struct PlacesMapViewRepresentable: UIViewRepresentable {

    //@Binding var viewModel: PlacesMapViewModel
    @Bindable var viewModel: PlacesMapViewModel
    @Binding private var places: [PlaceUI]

    init(viewModel: PlacesMapViewModel, places: Binding<[PlaceUI]>) {
        self.viewModel = viewModel
        self._places = places
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // Gestures
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        mapView.addGestureRecognizer(longPress)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        
        // Execute action if changed
        if let action = viewModel.currentAction,
           action != context.coordinator.lastAction {
            
            context.coordinator.lastAction = action
            executeAction(action, on: mapView)
            
            // Reset action after execution
            DispatchQueue.main.async {
                viewModel.currentAction = nil
            }
        }
        
        // Update region (only if changed to avoid loops)
        if !mapView.region.isApproximatelyEqual(to: viewModel.mapSettings.currentRegion) {
            mapView.setRegion(viewModel.mapSettings.currentRegion, animated: true)
        }
        
        // Update annotations
        updateAnnotations(mapView)
        
        // Update selection
        /*
        if let selected = viewModel.selectedPlace {
            let annotation = mapView.annotations.first {
                ($0 as? PlaceAnnotation)?.id == selected.id
            }
            mapView.selectAnnotation(annotation, animated: true)
        }
         */
    }
    
    private func executeAction(_ action: PlacesMapViewModel.MapAction, on mapView: MKMapView) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    private func updateAnnotations(_ mapView: MKMapView) {
        
        /*
        let newAnnotations = places.map { <#PlaceUI#> in
            <#code#>
        }
         */
        
        let current = mapView.annotations.compactMap { $0 as? PlaceAnnotation }
        
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
    }
}

extension PlacesMapViewRepresentable {

    @MainActor
    class Coordinator: NSObject, MKMapViewDelegate {

        let viewModel: PlacesMapViewModel
        var lastAction: PlacesMapViewModel.MapAction?

        init(viewModel: PlacesMapViewModel) {
            self.viewModel = viewModel
        }
        
        // MARK: - Gestures
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // viewModel.addPlace(at: coordinate)
        }
        
        // MARK: - MKMapViewDelegate
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
                        
            
            /*
            guard let placeAnnotation = annotation as? PlaceAnnotation else {
                return nil
            }
            
            let identifier = "PlacePin"
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier
            ) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
            
            view.annotation = placeAnnotation
            view.markerTintColor = placeAnnotation.color
            view.glyphImage = placeAnnotation.icon
            view.canShowCallout = true
            
            return view
             */
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//            guard let annotation = view.annotation as? PlaceAnnotation else { return }
//            viewModel.selectPlace(annotation)
        }
        
//        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//            <#code#>
//        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            // Update ViewModel when user pans/zooms
            viewModel.mapSettings.currentMKCamera = mapView.camera
            viewModel.mapSettings.currentRegion = mapView.region
            viewModel.mapSettings.currentRect = mapView.visibleMapRect
        }
    }
}
#endif
