//
//  MKPlaceAnnotation.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/3/26.
//

import MapKit

@MainActor
class MKPlaceAnnotation: NSObject, MKAnnotation {
    
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let color: UIColor
    let icon: UIImage?
    let place: PlaceUI
    
    init(place: PlaceUI) {
        self.id = place.id
        self.coordinate = place.coordinates
        self.title = place.name
        self.subtitle = ""
        self.color = UIColor(place.group?.color ?? .gray)
        if let group = place.group {
            self.icon = UIImage(icon: group.icon)
        } else {
            self.icon = nil
        }
        self.place = place
        super.init()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MKPlaceAnnotation else { return false }
        return id == other.id
    }
    
    override var hash: Int {
        id.hashValue
    }
}
