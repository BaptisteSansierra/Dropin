//
//  MKPlaceAnnotationRepresentable.swift
//  Dropin
//

import MapKit

/// Shared identity for the two place-annotation kinds: `MKPlaceDotAnnotation` (always present for every active place) and `MKPlacePromotedAnnotation`
@MainActor
protocol MKPlaceAnnotationRepresentable: MKAnnotation {
    var id: UUID { get }
    var place: PlaceUI { get }
    init(place: PlaceUI)
}

@MainActor
extension MKPlaceAnnotationRepresentable {
    var color: UIColor { UIColor(place.group?.color ?? .gray) }
}
