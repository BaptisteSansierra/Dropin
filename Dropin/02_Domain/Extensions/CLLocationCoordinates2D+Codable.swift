//
//  CLLocationCoordinates2D+Codable.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D: @retroactive Codable {

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(latitude, forKey: .latitude)
        try c.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: any Decoder) throws {
        var c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(latitude: 0, longitude: 0)
        self.latitude = try c.decode(CLLocationDegrees.self, forKey: .latitude)
        self.longitude = try c.decode(CLLocationDegrees.self, forKey: .longitude)
    }
}
