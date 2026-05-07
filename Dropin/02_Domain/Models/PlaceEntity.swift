//
//  Place.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import CoreLocation
import ContactFieldKit

struct PlaceEntity: Hashable, Sendable {
    let id: UUID
    let name: String
    let coordinates: CLLocationCoordinate2D
    let address: String
    let address2: String
    let tags: [TagEntity]
    let group: GroupEntity?
    let icon: Icon?
    let createdAt: Date
    let rating: Float?
    let phone: [String]
    let email: [String]
    let url: [String]
    let notes: String?
    let images: [UUID]
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
         phone: [String] = [],
         email: [String] = [],
         url: [String] = [],
         notes: String? = nil,
         images: [UUID] = [],
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
    
    init(other: PlaceEntity,
         tags: [TagEntity],
         group: GroupEntity? = nil) {
        self.id = other.id
        self.name = other.name
        self.coordinates = other.coordinates
        self.address = other.address
        self.address2 = other.address2
        self.icon = other.icon
        self.rating = other.rating
        self.phone = other.phone
        self.email = other.email
        self.url = other.url
        self.notes = other.notes
        self.images = other.images
        self.createdAt = other.createdAt
        self.deletedAt = other.deletedAt
        //
        self.tags = tags
        self.group = group
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
