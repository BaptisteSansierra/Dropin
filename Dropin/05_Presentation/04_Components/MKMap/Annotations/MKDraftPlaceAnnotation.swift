//
//  MKDraftPlaceAnnotation.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/3/26.
//

import UIKit
import MapKit

/// Used for a temporary being created (no place existing still)
@MainActor
class MKDraftPlaceAnnotation: NSObject, @MainActor MKAnnotation {
    
    let id: UUID
    @objc dynamic var coordinate: CLLocationCoordinate2D // KVO-observable so not needed to remove+recreate annotation at update
    let title: String?
    let subtitle: String?
    let icon: UIImage?
    
    init(coordinate: CLLocationCoordinate2D) {
        self.id = UUID()
        self.coordinate = coordinate
        self.title = ""
        self.subtitle = ""
        self.icon = UIImage(systemName: "plus.circle")
        super.init()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MKDraftPlaceAnnotation else { return false }
        return id == other.id
    }
    
    override var hash: Int {
        id.hashValue
    }
}
