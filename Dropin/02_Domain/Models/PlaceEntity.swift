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
    var tags: [TagEntity]
    var group: GroupEntity?
    let images: [UUID]
    let icon: Icon?
    let rating: Float?
    let phone: [String]
    let email: [String]
    let url: [String]
    let notes: String?
    // Dates
    var createdAt: Date     // Set at creation
    var updatedAt: Date     // Set on every mutation; drives dirty detection
    var deletedAt: Date?    // Soft delete

    // Used by mappers
    init(id: UUID,
         name: String,
         coordinates: CLLocationCoordinate2D,
         address: String,
         address2: String,
         tags: [TagEntity],
         group: GroupEntity?,
         images: [UUID] = [],
         icon: Icon?,
         rating: Float?,
         phone: [String],
         email: [String],
         url: [String],
         notes: String?,
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date?) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = address
        self.address2 = address2
        self.tags = tags
        self.group = group
        self.images = images
        self.icon = icon
        self.rating = rating
        self.phone = phone
        self.email = email
        self.url = url
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    /// Used to create a new place (Mapstr import / CatOpenData import / ...)
    init(id: UUID,
         name: String,
         coordinates: CLLocationCoordinate2D,
         address: String,
         tags: [TagEntity],
         group: GroupEntity? = nil,
         icon: Icon? = nil,
         notes: String? = nil) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = address
        self.tags = tags
        self.group = group
        self.icon = icon

        self.address2 = ""
        self.rating = nil
        self.phone = []
        self.email = []
        self.url = []
        self.notes = notes
        self.images = []
        
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
    }
    
    func deleted(deletedAt: Date) -> PlaceEntity {
        var copy = self
        copy.deletedAt = deletedAt
        return copy
    }

//    func undeleted() -> PlaceEntity {
//        var copy = self
//        copy.deletedAt = nil
//        return copy
//    }

    func updated() -> PlaceEntity {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }

    func replacedGroupAndTags(group: GroupEntity?, tags: [TagEntity]) -> PlaceEntity {
        var copy = self
        copy.group = group
        copy.tags = tags
        return copy
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension PlaceEntity {
    
    var isActive: Bool { deletedAt == nil }
    
    func isIdentical(name: String, coords: CLLocationCoordinate2D) -> Bool {
        // Let's not be too strict with place's case, the coords check is strong enough
        let compareName = self.name.lowercased() == name.lowercased()
        let compareCoords = self.coordinates.isIdentical(to: coords)
        return compareName && compareCoords
    }
}
