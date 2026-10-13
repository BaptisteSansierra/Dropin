//
//  LookupResolvedItem.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/26.
//

import MapKit

struct LookupResolvedItem: Identifiable {

    var id: String {
        "\(mapItem.resolvedCoordinates().latitude)-\(mapItem.resolvedCoordinates().latitude)"
    }
    let isPOI: Bool
    let mapItem: MKMapItem
    let address: String
    let coordinates: CLLocationCoordinate2D
    let distance: String?

    init(mapItem: MKMapItem,
         isPOI: Bool,
         address: String,
         coordinates: CLLocationCoordinate2D,
         distance: String?) {
        self.isPOI = isPOI
        self.mapItem = mapItem
        self.address = address
        self.coordinates = coordinates
        self.distance = distance
    }
}
