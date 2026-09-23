//
//  AnnotationViewFactory.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/3/26.
//

import MapKit
import SwiftUI

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
        static let dot = "PlaceDot"
        static let tempPlace = "TmpPlacePin"
        static let cluster = "ClusterPin"
        static let promotedPlace = "PromotedPlace"
    }

    private var mapSettings: MapSettings
    // See `PlacesMKMapVCR.Configuration.displayAllPins`.
    private var displayAllPins: Bool

    init(mapSettings: MapSettings, displayAllPins: Bool = false) {
        self.mapSettings = mapSettings
        self.displayAllPins = displayAllPins
    }

    func registerViews(for mapView: MKMapView) {
        mapView.register(PlaceAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: Identifiers.tempPlace)
        if mapPinMode == .apple {
            mapView.register(MKMarkerAnnotationView.self,
                             forAnnotationViewWithReuseIdentifier: Identifiers.applePlace)
        } else {
            mapView.register(DotAnnotationView.self,
                             forAnnotationViewWithReuseIdentifier: Identifiers.dot)
            mapView.register(PlaceAnnotationView.self,
                             forAnnotationViewWithReuseIdentifier: Identifiers.promotedPlace)
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
        if let tmp = annotation as? MKDraftPlaceAnnotation {
            return createTmpPlaceView(for: tmp, on: mapView)
        }

        if mapPinMode == .apple {
            guard let placeAnnotation = annotation as? MKPlaceAnnotationRepresentable else { return nil }
            return createPlaceAppleMarkerView(for: placeAnnotation, on: mapView)
        }

        // Promoted overlay: always a full pin.
        if let promoted = annotation as? MKPlacePromotedAnnotation {
            return createPlaceView(for: promoted, on: mapView)
        }

        // Base place annotation: a full pin when clustering owns density,
        // otherwise a dot (the promoted overlay handles full-detail display).
        guard let dotAnnotation = annotation as? MKPlaceDotAnnotation else {
            return nil
        }
        guard !mapSettings.clustering else {
            return createPlaceView(for: dotAnnotation, on: mapView)
        }
        return createDotView(for: dotAnnotation, on: mapView)
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

    private func createTmpPlaceView(for placeAnnotation: MKDraftPlaceAnnotation,
                                           on mapView: MKMapView) -> MKAnnotationView {
        let identifier = Identifiers.tempPlace
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier,
                                                         for: placeAnnotation) as? PlaceAnnotationView
            ?? PlaceAnnotationView(annotation: placeAnnotation, reuseIdentifier: identifier)
        view.annotation = placeAnnotation
        view.temporary = true
        view.isEnabled = false
        view.canShowCallout = false
        // No place identity yet, use a neutral color
        view.configure(color: UIColor(Color.dropinPrimary),
                       icon: nil,
                       iconExtra: nil,
                       pinStyle: mapSettings.pinStyle,
                       size: mapSettings.pinSize,
                       title: nil,
                       showLabel: false)
        return view
    }

    // Create an apple default Marker (development only)
    private func createPlaceAppleMarkerView(for placeAnnotation: any MKPlaceAnnotationRepresentable,
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

    // Create a regular place (promoted overlay, or the base annotation when clustering is on)
    private func createPlaceView(for placeAnnotation: any MKPlaceAnnotationRepresentable,
                                 on mapView: MKMapView) -> MKAnnotationView {
        // DEBUG: swapped to a plain UIKit ring (no UIHostingController) to test
        // whether the hosting-controller layer is the cause of pin/map decorrelation.
        let identifier = Identifiers.promotedPlace
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier,
                                                         for: placeAnnotation) as? PlaceAnnotationView
            ?? PlaceAnnotationView(annotation: placeAnnotation, reuseIdentifier: identifier)
        view.annotation = placeAnnotation
        view.displayPriority = displayAllPins ? .required : .defaultHigh
        view.collisionMode = .circle
        view.configure(color: placeAnnotation.color,
                       icon: placeAnnotation.place.group?.icon,
                       iconExtra: placeAnnotation.place.icon,
                       pinStyle: mapSettings.pinStyle,
                       size: mapSettings.pinSize,
                       title: placeAnnotation.place.name,
                       showLabel: declutterState(for: mapView))
        if mapSettings.clustering {
            view.clusteringIdentifier = "PlaceCluster"
        }
        return view
    }

    // Create a dot for a place not currently promoted (no-cluster mode only)
    private func createDotView(for placeAnnotation: MKPlaceDotAnnotation,
                               on mapView: MKMapView) -> MKAnnotationView {
        let identifier = Identifiers.dot
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier,
                                                         for: placeAnnotation) as? DotAnnotationView
            ?? DotAnnotationView(annotation: placeAnnotation, reuseIdentifier: identifier)
        view.annotation = placeAnnotation
        view.configure(color: placeAnnotation.color)
        return view
    }

    // MARK: - Declutter

    /// Single source of truth for whether labels should show at the current
    /// camera altitude. Used both at annotation-view creation time and when
    /// refreshing already-created views on camera settle.
    private func declutterState(for mapView: MKMapView) -> Bool {
        mapView.camera.altitude < DropinApp.map.mapLabelHideAltitude
    }

    /// Called on camera-settle to refresh already-created annotation views
    /// `createPlaceView` only runs once per dequeue, so
    /// without this, showLabel would get stuck at whatever altitude was current the last time MapKit dequeued that specific view.
    mutating func refreshDeclutterState(on mapView: MKMapView) {
        let showLabel = declutterState(for: mapView)

        // Only touch views actually on screen that are currently full pins
        // bounds the cost to what's visible regardless of how many places/annotations exist total.
        for annotation in mapView.annotations(in: mapView.visibleMapRect) {
            guard let annotation = annotation as? MKAnnotation else { continue }

            if let view = mapView.view(for: annotation) as? PlaceAnnotationView {
                view.showLabel = showLabel
            }
        }
    }
}
