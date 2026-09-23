//
//  MKPlaceDotAnnotation.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/3/26.
//

import MapKit

/// Used to display a simple dot, permanent, each place has his dot on the map
@MainActor
class MKPlaceDotAnnotation: NSObject, MKPlaceAnnotationRepresentable {

    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let place: PlaceUI

    required init(place: PlaceUI) {
        self.id = place.id
        self.coordinate = place.coordinates
        self.title = place.name
        self.subtitle = ""
        self.place = place
        super.init()
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MKPlaceDotAnnotation else { return false }
        return id == other.id
    }

    override var hash: Int {
        id.hashValue
    }
}
