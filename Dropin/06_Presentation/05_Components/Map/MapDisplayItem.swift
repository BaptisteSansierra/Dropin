//
//  MapDisplayItem.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/10/25.
//

import Foundation
import CoreLocation
import MapKit

@MainActor
class MapDisplayItem: Identifiable, Equatable {
    let id: String
    let center: CLLocationCoordinate2D
    
    init(id: String, center: CLLocationCoordinate2D) {
        self.id = id
        self.center = center
    }
    
    nonisolated static func == (lhs: MapDisplayItem, rhs: MapDisplayItem) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class MapDisplayPlaceItem: MapDisplayItem {

    let place: PlaceUI

    init(place: PlaceUI) {
        self.place = place
        super.init(id: place.id, center: place.coordinates)
    }
}

@MainActor
class MapDisplayClusterItem: MapDisplayItem {
    
    let points: [CLLocationCoordinate2D]
    var span: MKCoordinateSpan {
        let result = points.reduce(MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)) { partialResult, coords in
            let latDelta = 2 * abs(center.latitude - coords.latitude)
            let lonDelta = 2 * abs(center.longitude - coords.longitude)
            return MKCoordinateSpan(latitudeDelta: partialResult.latitudeDelta > latDelta ? partialResult.latitudeDelta : latDelta,
                                    longitudeDelta: partialResult.longitudeDelta > lonDelta ? partialResult.longitudeDelta : lonDelta)
        }
        // Add a margin
        return MKCoordinateSpan(latitudeDelta: result.latitudeDelta * 1.5,
                                longitudeDelta: result.longitudeDelta * 1.5)
    }

    init(places: [PlaceUI]) {
        guard places.count > 1 else {
            self.points = [CLLocationCoordinate2D]()
            super.init(id: UUID().uuidString, center: CLLocationCoordinate2D.zero)
            assertionFailure("cannot create cluster from \(places.count) place")
            return
        }
        let identifier = places.reduce("") { "\($0)-\($1.id)" }
        self.points = places.map({ $0.coordinates })
        // Compute center
        let latitude = points.reduce(0.0) { $0 + $1.latitude } / Double(points.count)
        let longitude = points.reduce(0.0) { $0 + $1.longitude } / Double(points.count)
        let center = CLLocationCoordinate2D(latitude: latitude,
                                            longitude: longitude)
        super.init(id: identifier, center: center)
    }
}
