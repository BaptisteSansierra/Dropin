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
        guard let other = object as? MKPlaceDotAnnotation else { return false }
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
