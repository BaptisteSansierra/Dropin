//
//  MKCoordinateRegion+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/3/26.
//

import MapKit

public extension MKCoordinateRegion {

    static var zero: MKCoordinateRegion {
        .init(
            center: CLLocationCoordinate2D.zero,
            span: .init(squareDelta: 0)
        )
    }

    static var barcelona: MKCoordinateRegion {
        .init(
            center: CLLocationCoordinate2D.barcelona,
            span: .init(squareDelta: 0.3)
        )
    }

    static var london: MKCoordinateRegion {
        .init(
            center: CLLocationCoordinate2D.london,
            span: .init(squareDelta: 0.3)
        )
    }

    static var abbeyRoad: MKCoordinateRegion {
        .init(
            center: CLLocationCoordinate2D.abbeyRoad,
            span: .init(squareDelta: 0.01)
        )
    }
    
    func offset(lat: CLLocationDegrees = 0, lon: CLLocationDegrees = 0) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: self.center.offset(x: lat, y: lon),
            span: self.span
        )
    }

    func isApproximatelyEqual(to other: MKCoordinateRegion, tolerance: Double = 0.0001) -> Bool {
        return abs(center.latitude - other.center.latitude) < tolerance &&
               abs(center.longitude - other.center.longitude) < tolerance &&
               abs(span.latitudeDelta - other.span.latitudeDelta) < tolerance &&
               abs(span.longitudeDelta - other.span.longitudeDelta) < tolerance
    }
}
