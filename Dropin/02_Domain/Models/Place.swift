//
//  Place.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import CoreLocation
import ContactFieldKit

struct Place: Hashable, Sendable {
    let id: UUID
    let name: String
    let coordinates: CLLocationCoordinate2D
    let address: String?
    let address2: String?
    var tags: [Tag]
    var category: Category?
    let images: [UUID]
    let icon: Icon?
    let rating: Float?
    let phone: [String]
    let email: [String]
    let url: [String]
    let notes: String?
    // Apple POI linking: set when this place was created from an Apple Maps point of interest; nil otherwise.
    // applePhone/appleURL are Apple's, locally cached, read-only for user
    // appleFetchedAt drives the refresh trigger
    let applePlaceID: String?
    let applePhone: String?
    let appleURL: String?
    let appleFetchedAt: Date?
    // Dates
    var createdAt: Date     // Set at creation
    var updatedAt: Date     // Set on every mutation; drives dirty detection
    var deletedAt: Date?    // Soft delete

    // Used by mappers
    init(id: UUID,
         name: String,
         coordinates: CLLocationCoordinate2D,
         address: String?,
         address2: String?,
         tags: [Tag],
         category: Category?,
         images: [UUID] = [],
         icon: Icon?,
         rating: Float?,
         phone: [String],
         email: [String],
         url: [String],
         notes: String?,
         applePlaceID: String? = nil,
         applePhone: String? = nil,
         appleURL: String? = nil,
         appleFetchedAt: Date? = nil,
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date?) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = Self.normalized(address)
        self.address2 = Self.normalized(address2)
        self.tags = tags
        self.category = category
        self.images = images
        self.icon = icon
        self.rating = rating
        self.phone = phone
        self.email = email
        self.url = url
        self.notes = notes
        self.applePlaceID = applePlaceID
        self.applePhone = applePhone
        self.appleURL = appleURL
        self.appleFetchedAt = appleFetchedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    /// Used to create a new place (Mapstr import / CatOpenData import / ...)
    init(id: UUID,
         name: String,
         coordinates: CLLocationCoordinate2D,
         address: String?,
         tags: [Tag],
         category: Category? = nil,
         icon: Icon? = nil,
         notes: String? = nil) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = Self.normalized(address)
        self.tags = tags
        self.category = category
        self.icon = icon

        self.address2 = nil
        self.rating = nil
        self.phone = []
        self.email = []
        self.url = []
        self.notes = notes
        self.images = []
        self.applePlaceID = nil
        self.applePhone = nil
        self.appleURL = nil
        self.appleFetchedAt = nil
        
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
    }
    
    /// "" is never a valid stored address — nil means "no address" (e.g. not yet fetched / offline lookup).
    /// Normalizing here catches empty strings from any source: legacy data predating this distinction,
    /// imports, or callers that haven't been updated to pass nil.
    private static func normalized(_ value: String?) -> String? {
        value?.isEmpty == true ? nil : value
    }

    func deleted(deletedAt: Date) -> Place {
        var copy = self
        copy.deletedAt = deletedAt
        return copy
    }

//    func undeleted() -> Place {
//        var copy = self
//        copy.deletedAt = nil
//        return copy
//    }

    func updated() -> Place {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }

    /// Used by AddressBackfillService once a reverse-geocode lookup resolves an
    /// address for a place that didn't have one yet.
    func withAddress(_ address: String) -> Place {
        Place(id: id,
                   name: name,
                   coordinates: coordinates,
                   address: address,
                   address2: address2,
                   tags: tags,
                   category: category,
                   images: images,
                   icon: icon,
                   rating: rating,
                   phone: phone,
                   email: email,
                   url: url,
                   notes: notes,
                   applePlaceID: applePlaceID,
                   applePhone: applePhone,
                   appleURL: appleURL,
                   appleFetchedAt: appleFetchedAt,
                   createdAt: createdAt,
                   updatedAt: updatedAt,
                   deletedAt: deletedAt)
    }

    func replacedCategoryAndTags(category: Category?, tags: [Tag]) -> Place {
        var copy = self
        copy.category = category
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

extension Place {
    
    var isActive: Bool { deletedAt == nil }
    
    func isIdentical(name: String, coords: CLLocationCoordinate2D) -> Bool {
        // Let's not be too strict with place's case, the coords check is strong enough
        let compareName = self.name.lowercased() == name.lowercased()
        let compareCoords = self.coordinates.isIdentical(to: coords)
        return compareName && compareCoords
    }
}
