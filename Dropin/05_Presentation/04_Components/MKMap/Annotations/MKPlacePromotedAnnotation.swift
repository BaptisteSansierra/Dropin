//
//  MKPlacePromotedAnnotation.swift
//  Dropin
//

import MapKit

/// Used for a promoted place, rendered as a full pin
@MainActor
class MKPlacePromotedAnnotation: NSObject, MKPlaceAnnotationRepresentable {

    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let place: PlaceUI

    init(place: PlaceUI) {
        self.id = place.id
        self.coordinate = place.coordinates
        self.title = place.name
        self.subtitle = ""
        self.place = place
        super.init()
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MKPlacePromotedAnnotation else { return false }
        return id == other.id
    }

    override var hash: Int {
        id.hashValue
    }
}
