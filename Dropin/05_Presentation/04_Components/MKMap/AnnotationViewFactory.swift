//
//  AnnotationViewFactory.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/3/26.
//

import MapKit

@MainActor
struct AnnotationViewFactory {

    // DEBUG: switch Apple vs. custom Annotations
    enum MapPinMode {
        case apple
        case custom
    }
    var mapPinMode: MapPinMode = .custom

    private enum Identifiers {
        static let applePlace = "ApplePlacePin"
        static let place = "PlacePin"
        static let tempPlace = "TmpPlacePin"
        static let cluster = "ClusterPin"
    }
    
    private var mapSettings: MapSettings

    // Last state applied by `refreshDeclutterState`, so unchanged settles
    // (the common case) skip the pin walk entirely instead of re-touching
    // every on-screen view for no reason.
    private var lastDeclutterState: (showLabel: Bool, priority: MKFeatureDisplayPriority)?

    init(mapSettings: MapSettings) {
        self.mapSettings = mapSettings
    }

    func registerViews(for mapView: MKMapView) {
        mapView.register(HostingAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: Identifiers.tempPlace)
        if mapPinMode == .apple {
            mapView.register(MKMarkerAnnotationView.self,
                             forAnnotationViewWithReuseIdentifier: Identifiers.applePlace)
        } else {
            mapView.register(HostingAnnotationView.self,
                             forAnnotationViewWithReuseIdentifier: Identifiers.place)
        }
        
        mapView.register(MKMarkerAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: Identifiers.cluster)
    }

    func view(for annotation: MKAnnotation,
              in mapView: MKMapView) -> MKAnnotationView? {
        // User location
        if annotation is MKUserLocation {
            return nil
        }
        
        // Cluster
        if let cluster = annotation as? MKClusterAnnotation {
            return createClusterView(for: cluster, on: mapView)
        }

        // Temporary place (used for creation)
        if let tmp = annotation as? MKTempPlaceAnnotation {
            return createTmpPlaceView(for: tmp, on: mapView)
        }

        // Individual place
        guard let placeAnnotation = annotation as? MKPlaceAnnotation else {
            return nil
        }
        
        if mapPinMode == .apple {
            return createPlaceMarkerView(for: placeAnnotation, on: mapView)
        }
        return createPlaceView(for: placeAnnotation, on: mapView)
    }

    
    private func createClusterView(for cluster: MKClusterAnnotation,
                                          on mapView: MKMapView) -> MKAnnotationView {
        let identifier = Identifiers.cluster
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier,
                                                         for: cluster) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: cluster, reuseIdentifier: identifier)
        view.markerTintColor = .systemBlue
        view.glyphText = "\(cluster.memberAnnotations.count)"
        view.displayPriority = .required
        return view
    }
    
    private func createTmpPlaceView(for placeAnnotation: MKTempPlaceAnnotation,
                                           on mapView: MKMapView) -> MKAnnotationView {
        let identifier = Identifiers.tempPlace
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier,
                                                         for: placeAnnotation) as? HostingAnnotationView
            ?? HostingAnnotationView(annotation: placeAnnotation, reuseIdentifier: identifier)
        view.annotation = placeAnnotation
        view.configure(mapSettings: mapSettings)
        view.temporary = true
        view.isEnabled = false
        view.canShowCallout = false
        return view
    }

    // Create an apple default Marker (development only)
    private func createPlaceMarkerView(for placeAnnotation: MKPlaceAnnotation,
                                              on mapView: MKMapView) -> MKAnnotationView {
        let identifier = Identifiers.applePlace
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier,
                                                         for: placeAnnotation) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: placeAnnotation, reuseIdentifier: identifier)
        view.annotation = placeAnnotation
        view.markerTintColor = UIColor(placeAnnotation.place.group?.color ?? .gray)
        if let group = placeAnnotation.place.group {
            view.glyphImage = UIImage(icon: group.icon)
        }
        view.canShowCallout = true
        if mapSettings.clustering {
            view.clusteringIdentifier = "PlaceCluster"
        }
        return view
    }

    // Create a regular place
    private func createPlaceView(for placeAnnotation: MKPlaceAnnotation,
                                 on mapView: MKMapView) -> MKAnnotationView {
        let identifier = Identifiers.place
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier,
                                                         for: placeAnnotation) as? HostingAnnotationView
            ?? HostingAnnotationView(annotation: placeAnnotation, reuseIdentifier: identifier)
        view.annotation = placeAnnotation
        let (showLabel, priority) = declutterState(for: mapView)
        view.showLabel = showLabel
        view.configure(mapSettings: mapSettings)
        if mapSettings.clustering {
            view.clusteringIdentifier = "PlaceCluster"
        }
        view.canShowCallout = false
        view.displayPriority = priority
        view.collisionMode = .circle
        return view
    }

    // MARK: - Declutter

    /// Single source of truth for how zoomed-out the map currently is. Used
    /// both at annotation-view creation time and when refreshing already-
    /// created views on camera settle.
    private func declutterState(for mapView: MKMapView) -> (showLabel: Bool, priority: MKFeatureDisplayPriority) {
        let altitude = mapView.camera.altitude
        let showLabel = altitude < DropinApp.map.mapLabelHideAltitude
        guard !mapSettings.clustering else {
            return (showLabel, .required)   // clustering already owns density; never drop glyphs ourselves
        }
        let priority: MKFeatureDisplayPriority = altitude > DropinApp.map.mapPinDropAltitude ? .defaultLow : .required
        return (showLabel, priority)
    }

    /// Called on camera-settle (not mid-gesture) to refresh already-created annotation views
    /// `createPlaceView` only runs once per dequeue, so
    /// without this, showLabel/displayPriority get stuck at whatever altitude
    /// was current the last time MapKit dequeued that specific view.
    mutating func refreshDeclutterState(on mapView: MKMapView) {
        let (showLabel, priority) = declutterState(for: mapView)

        // Skip the walk entirely if the altitude bucket didn't actually change
        // At high pin density, reconfiguring every view on every settle (even a no-op one) is too expensive
        if let last = lastDeclutterState, last.showLabel == showLabel, last.priority == priority {
            return
        }
        lastDeclutterState = (showLabel, priority)

        // Only touch pins actually on screen, not every places
        // Bounds the cost to what's visible regardless of how many places exist total.
        let visiblePlaces = mapView.annotations(in: mapView.visibleMapRect)
            .compactMap { $0 as? MKPlaceAnnotation }
        for placeAnnotation in visiblePlaces {
            guard let view = mapView.view(for: placeAnnotation) as? HostingAnnotationView else { continue }
            view.showLabel = showLabel
            view.displayPriority = priority
        }
    }
}
