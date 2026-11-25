//
//  MapController.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/6/26.
//
//  Imperative handle the consumer holds to operate on the map after the
//  representable is live. Holds a weak reference to the Coordinator; all
//  calls are no-ops until the wiring runs in `makeUIViewController`.
//

import Foundation
import MapKit
import CoreLocation

@MainActor
final class MapController {

    private(set) weak var coordinator: PlacesMKMapVCR.Coordinator?

    init() {}

    /// Called by `PlacesMKMapVCR.makeUIViewController(_:)` once the map exists.
    func connect(_ coordinator: PlacesMKMapVCR.Coordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Camera state (read-only snapshots)
    var camera: MKMapCamera?         { coordinator?.mapView?.camera }
    var region: MKCoordinateRegion?  { coordinator?.mapView?.region }
    var visibleMapRect: MKMapRect?   { coordinator?.mapView?.visibleMapRect }

    // MARK: - Projection
    func coordinate(at point: CGPoint) -> CLLocationCoordinate2D? {
        guard let mv = coordinator?.mapView else { return nil }
        return mv.convert(point, toCoordinateFrom: mv)
    }

    func point(for coordinate: CLLocationCoordinate2D) -> CGPoint? {
        guard let mv = coordinator?.mapView else { return nil }
        return mv.convert(coordinate, toPointTo: mv)
    }

    // MARK: - Imperative ops (forwarded to the Coordinator)

    func centerOn(_ coords: CLLocationCoordinate2D,
                  withSheetOffset: Bool,
                  animated: Bool = true) {
        coordinator?.centerOn(coords: coords,
                              withSheetOffset: withSheetOffset,
                              animated: animated)
    }

    func fitAll(animated: Bool = true) {
        coordinator?.fitAll(animated: animated)
    }
}
