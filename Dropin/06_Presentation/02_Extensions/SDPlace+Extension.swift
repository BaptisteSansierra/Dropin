//
//  SDPlace+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/8/25.
//

import SwiftUI
import CoreLocation

extension PlaceEntity {
    
    var groupColorOrDefault: Color {
        guard let gc = groupColor else { return .dropinPrimary }
        return Color(rgba: gc)
    }
    /*
    var coordinates: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func distanceTo(coords: CLLocationCoordinate2D) -> Double {
        return LocationManager.distance(from: coords, to: self.coordinates)
    }
     */
}

