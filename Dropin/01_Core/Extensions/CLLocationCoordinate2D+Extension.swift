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

    func offset(x: Double, y: Double) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude + x,
                                      longitude: longitude + y)
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    static public func == (lhs: Self, rhs: Self) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
