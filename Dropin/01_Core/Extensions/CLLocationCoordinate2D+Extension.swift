//
//  CLLocationCoordinate2D+Extension.swift
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
}
