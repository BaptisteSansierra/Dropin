//
//  Place.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import CoreLocation
import ContactFieldKit

struct PlaceEntity: Hashable {
    let id: UUID
    var name: String
    var coordinates: CLLocationCoordinate2D //= CLLocationCoordinate2D.zero
    var address: String
    var address2: String
    var tags: [TagEntity]
    var group: GroupEntity?
    var icon: Icon?
    var creationDate: Date
    var rating: Float?
    var phone: [ContactItem]
    var email: [ContactItem]
    var url: [ContactItem]
    var notes: String?
    var images: [Data]
    var deletionDate: Date? = nil

    init(id: UUID,
         name: String,
         coordinates: CLLocationCoordinate2D,
         address: String,
         address2: String,
         tags: [TagEntity],
         group: GroupEntity? = nil,
         icon: Icon? = nil,
         rating: Float? = nil,
         phone: [ContactItem] = [],
         email: [ContactItem] = [],
         url: [ContactItem] = [],
         notes: String? = nil,
         images: [Data] = [],
         creationDate: Date,
         deletionDate: Date? = nil) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = address
        self.address2 = address2
        self.icon = icon
        self.tags = tags
        self.group = group
        self.icon = icon
        self.rating = rating
        self.phone = phone
        self.email = email
        self.url = url
        self.notes = notes
        self.images = images
        self.creationDate = creationDate
        self.deletionDate = deletionDate
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
