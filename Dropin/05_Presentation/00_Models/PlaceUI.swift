//
//  PlaceUI.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI
import CoreLocation
import ContactFieldKit

struct PlaceUIRef: Hashable {
    let place: PlaceUI
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.place.id == rhs.place.id }
    func hash(into hasher: inout Hasher) { hasher.combine(place.id) }
}

struct PlaceImageUI: Identifiable {
    let id: UUID            // local identity, always set
    var dbId: UUID?         // nil = not yet in DB
    var thumbnail: Data?
    var fullImage: UIImage? // only set for pending additions (dbId == nil)

    var isThumbnailLoading: Bool { dbId != nil && thumbnail == nil }

    init(id: UUID = UUID(), dbId: UUID? = nil, thumbnail: Data? = nil, fullImage: UIImage? = nil) {
        self.id = id
        self.dbId = dbId
        self.thumbnail = thumbnail
        self.fullImage = fullImage
    }
}

@MainActor
@Observable class PlaceUI: Identifiable, @MainActor Equatable {

    let id: UUID
    var name: String = ""
    var coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D.zero
    var address: String = ""
    var address2: String = ""
    var icon: Icon? = nil
    var tags: [TagUI] = [TagUI]()
    var group: GroupUI? = nil
    var images: [PlaceImageUI] = []
    var rating: Float? = nil
    var phone: [ContactItem] = []
    var email: [ContactItem] = []
    var url: [ContactItem] = []
    var notes: String? = nil
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date? = nil
    
    var groupColor: Color {
        guard let group = self.group else { return .dropinPrimary }
        return group.color
    }
    
    var isActive: Bool {
        deletedAt == nil
    }

    var changeToken: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(coordinates)
        hasher.combine(address)
        hasher.combine(address2)
        hasher.combine(icon?.rawValue)
        hasher.combine(tags.map(\.id))
        hasher.combine(images.map(\.id))  // local UUIDs: changes on add/remove, not on thumbnail load
        hasher.combine(group?.id)
        hasher.combine(rating)
        hasher.combine(phone.map(\.rawValue))
        hasher.combine(email.map(\.rawValue))
        hasher.combine(url.map(\.rawValue))
        hasher.combine(notes)
        return hasher.finalize()
    }

    static func == (lhs: PlaceUI, rhs: PlaceUI) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: UUID,
         name: String,
         coordinates: CLLocationCoordinate2D,
         address: String,
         address2: String,
         tags: [TagUI],
         group: GroupUI? = nil,
         images: [PlaceImageUI] = [],
         icon: Icon? = nil,
         rating: Float? = nil,
         phone: [ContactItem] = [],
         email: [ContactItem] = [],
         url: [ContactItem] = [],
         notes: String? = nil,
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date? = nil) {
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

    init(coordinates: CLLocationCoordinate2D) {
        id = UUID()
        self.coordinates = coordinates
        let now = Date()
        createdAt = now
        updatedAt = now
    }
    
    func copy() -> PlaceUI {
        return PlaceUI(id: id,
                       name: name,
                       coordinates: coordinates,
                       address: address,
                       address2: address2,
                       tags: tags,
                       group: group,
                       images: images,
                       icon: icon,
                       rating: rating,
                       phone: phone,
                       email: email,
                       url: url,
                       notes: notes,
                       createdAt: createdAt,
                       updatedAt: updatedAt,
                       deletedAt: deletedAt)
    }
    
    func update(from other: PlaceUI) {
        name        = other.name
        coordinates = other.coordinates
        address     = other.address
        address2    = other.address2
        tags        = other.tags
        group       = other.group
        images      = other.images
        icon        = other.icon
        rating      = other.rating
        phone       = other.phone
        email       = other.email
        url         = other.url
        notes       = other.notes
        updatedAt   = Date()
    }
    
    func isContentEqual(_ other: PlaceUI) -> Bool {
        guard id == other.id else { return false }
        guard name == other.name else { return false }
        guard coordinates == other.coordinates else { return false }
        guard address == other.address else { return false }
        guard address2 == other.address2 else { return false }
        guard tags == other.tags else { return false }
        guard group == other.group else { return false }
        guard icon == other.icon else { return false }
        guard rating == other.rating else { return false }
        guard phone == other.phone else { return false }
        guard email == other.email else { return false }
        guard url == other.url else { return false }
        guard notes == other.notes else { return false }
        let selfDbIds = Set(images.compactMap(\.dbId))
        let otherDbIds = Set(other.images.compactMap(\.dbId))
        let hasPending = images.contains { $0.dbId == nil }
        guard selfDbIds == otherDbIds && !hasPending else { return false }
        return true
    }
}
