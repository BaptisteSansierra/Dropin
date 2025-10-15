//
//  Place.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import CoreLocation

struct PlaceEntity: Hashable {
    let id: String
    var name: String = ""
    var coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D.zero
    var address: String = ""
    var systemImage: String = "tag"
    var tags: [TagEntity] = [TagEntity]()
    var group: GroupEntity? = nil
    var notes: String? = nil
    var phone: String? = nil
    var url: String? = nil
    var creationDate: Date
    // following propertie are not part of the DB model
    /// When  databaseDeleted is true, domain objects should be ignored
    var databaseDeleted: Bool = false

    init(id: String, name: String, coordinates: CLLocationCoordinate2D, address: String, systemImage: String, tags: [TagEntity], group: GroupEntity? = nil, notes: String? = nil, phone: String? = nil, url: String? = nil, creationDate: Date, databaseDeleted: Bool = false) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = address
        self.systemImage = systemImage
        self.tags = tags
        self.group = group
        self.notes = notes
        self.phone = phone
        self.url = url
        self.creationDate = creationDate
        self.databaseDeleted = databaseDeleted
    }
    
//    init(coordinates: CLLocationCoordinate2D) {
//        id = UUID().uuidString
//        self.coordinates = coordinates
//        creationDate = Date()
//    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
