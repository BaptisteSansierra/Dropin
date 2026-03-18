//
//  PlaceAnnotationModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/3/26.
//

import Foundation
import CoreLocation
import ClusterMap

struct PlaceAnnotationModel: Identifiable, Equatable, CoordinateIdentifiable, Hashable {
    var id = UUID()
    var coordinate: CLLocationCoordinate2D
    var placeId: UUID
    
    init(coordinates: CLLocationCoordinate2D, placeId: UUID) {
        self.coordinate = coordinates
        self.placeId = placeId
    }
}
