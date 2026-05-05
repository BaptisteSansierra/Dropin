//
//  CLLocationCoordinate2D+Utils.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/8/25.
//

import CoreLocation

extension CLLocationCoordinate2D {
    
    static var zero: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    
    func isInside(minLatitude: Double, maxLatitude: Double, minLongitude: Double, maxLongitude: Double) -> Bool {
        return self.latitude >= minLatitude &&
               self.latitude <= maxLatitude &&
               self.longitude >= minLongitude &&
               self.longitude <= maxLongitude
    }

    func offset(x: CLLocationDegrees = 0, y: CLLocationDegrees = 0) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude + x,
                                      longitude: longitude + y)
    }
    
    func distance(to other: CLLocationCoordinate2D) -> Double {
        let l1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let l2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return l1.distance(from: l2)
    }
}
