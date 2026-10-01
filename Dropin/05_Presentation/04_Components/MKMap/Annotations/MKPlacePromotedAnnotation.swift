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
    let place: PlaceUIModel
    private let updatedAt: Date

    required init(place: PlaceUIModel) {
        self.id = place.id
        self.coordinate = place.coordinates
        self.title = place.name
        self.subtitle = ""
        self.place = place
        self.updatedAt = place.updatedAt
        super.init()
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MKPlacePromotedAnnotation else { return false }
        // MapKit's internal annotation tracking uses isEqual/hash
        // we need to rely on ID + updatedAt for a right equality result
        return id == other.id && updatedAt == other.updatedAt
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(updatedAt)
        return hasher.finalize()
    }
}
