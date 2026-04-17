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
    let name: String
    let coordinates: CLLocationCoordinate2D
    let address: String
    let address2: String
    var tags: [TagEntity]
    var group: GroupEntity?
    let icon: Icon?
    let createdAt: Date
    let rating: Float?
    let phone: [ContactItem]
    let email: [ContactItem]
    let url: [ContactItem]
    let notes: String?
    let images: [Data]
    let deletedAt: Date?

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
         createdAt: Date,
         deletedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = address
        self.address2 = address2
        self.tags = tags
        self.group = group
        self.icon = icon
        self.rating = rating
        self.phone = phone
        self.email = email
        self.url = url
        self.notes = notes
        self.images = images
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
