//
//  GeoJSONGeometry.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/11/26.
//

import Foundation
import CoreLocation

struct GeoJSONGeometry: Decodable {
    let coordinates: [Double]
}

extension GeoJSONGeometry {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinates[1],
                               longitude: coordinates[0])
    }
}
