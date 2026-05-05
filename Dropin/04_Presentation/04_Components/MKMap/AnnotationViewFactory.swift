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
    
    private var appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
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

    func view(for annotation: MKAnnotation, in mapView: MKMapView) -> MKAnnotationView? {
        // User location
        if annotation is MKUserLocation {
            return nil
        }
        
        // Cluster
        if let cluster = annotation as? MKClusterAnnotation {
            return createClusterView(for: cluster, on: mapView)
        }

        // Tmp
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
        view.configure(appSettings: appSettings)
        view.temporary = true
        view.isEnabled = false
        view.canShowCallout = false
        return view
    }

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
        view.clusteringIdentifier = "PlaceCluster"
        return view
    }

    private func createPlaceView(for placeAnnotation: MKPlaceAnnotation,
                                 on mapView: MKMapView) -> MKAnnotationView {
        let identifier = Identifiers.place
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier,
                                                         for: placeAnnotation) as? HostingAnnotationView
            ?? HostingAnnotationView(annotation: placeAnnotation, reuseIdentifier: identifier)
        view.annotation = placeAnnotation
        view.configure(appSettings: appSettings)
        view.clusteringIdentifier = "PlaceCluster"
        view.canShowCallout = false
        view.displayPriority = .required
        view.collisionMode = .circle
        return view
    }
}
