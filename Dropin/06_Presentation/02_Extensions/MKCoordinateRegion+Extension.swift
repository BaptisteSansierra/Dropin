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
}
