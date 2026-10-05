//
//  PlaceUIModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI
import CoreLocation
import ContactFieldKit

struct PlaceUIModelRef: Hashable {
    let place: PlaceUIModel
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.place.id == rhs.place.id }
    func hash(into hasher: inout Hasher) { hasher.combine(place.id) }
}

struct PlaceImageUIModel: Identifiable {
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
@Observable class PlaceUIModel: Identifiable {
    let id: UUID
    var name: String = ""
    var coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D.zero
    // "" is never a valid stored address — nil means "no address" (e.g. not yet fetched / offline lookup).
    // Normalizing on every set catches empty strings from any writer (bindings, placeholders, etc.).
    var address: String? = nil {
        didSet {
            if address?.isEmpty == true { address = nil }
        }
    }
    var address2: String? = nil {
        didSet {
            if address2?.isEmpty == true { address2 = nil }
        }
    }
    var icon: Icon? = nil
    var tags: [TagUIModel] = [TagUIModel]()
    var category: CategoryUIModel? = nil
    var images: [PlaceImageUIModel] = []
    var rating: Float? = nil
    var phone: [ContactItem] = []
    var email: [ContactItem] = []
    var url: [ContactItem] = []
    var notes: String? = nil
    var applePlaceID: String? = nil
    var applePhone: String? = nil
    var appleURL: String? = nil
    var appleFetchedAt: Date? = nil
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date? = nil
    
    var groupColor: Color {
        guard let category = self.category else { return .dropinPrimary }
        return category.color
    }
    
    var isActive: Bool {
        deletedAt == nil
    }

    var hasNoAddress: Bool {
        (address ?? "").isEmpty
    }

    var changeToken: Int {
        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(coordinates)
        hasher.combine(address)
        hasher.combine(address2)
        hasher.combine(icon?.rawValue)
        hasher.combine(tags.map(\.id))
        hasher.combine(images.map(\.id))  // local UUIDs: changes on add/remove, not on thumbnail load
        hasher.combine(category?.id)
        hasher.combine(rating)
        hasher.combine(phone.map(\.rawValue))
        hasher.combine(email.map(\.rawValue))
        hasher.combine(url.map(\.rawValue))
        hasher.combine(notes)
        hasher.combine(applePlaceID)
        hasher.combine(applePhone)
        hasher.combine(appleURL)
        hasher.combine(appleFetchedAt)
        return hasher.finalize()
    }
    
    init(id: UUID,
         name: String,
         coordinates: CLLocationCoordinate2D,
         address: String?,
         address2: String?,
         tags: [TagUIModel],
         category: CategoryUIModel? = nil,
         images: [PlaceImageUIModel] = [],
         icon: Icon? = nil,
         rating: Float? = nil,
         phone: [ContactItem] = [],
         email: [ContactItem] = [],
         url: [ContactItem] = [],
         notes: String? = nil,
         applePlaceID: String? = nil,
         applePhone: String? = nil,
         appleURL: String? = nil,
         appleFetchedAt: Date? = nil,
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = address
        self.address2 = address2
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

    init(coordinates: CLLocationCoordinate2D) {
        id = UUID()
        self.coordinates = coordinates
        let now = Date()
        createdAt = now
        updatedAt = now
    }
    
    func copy() -> PlaceUIModel {
        return PlaceUIModel(id: id,
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
    
    func update(from other: PlaceUIModel) {
        name        = other.name
        coordinates = other.coordinates
        address     = other.address
        address2    = other.address2
        tags        = other.tags
        category    = other.category
        images      = other.images
        icon        = other.icon
        rating      = other.rating
        phone       = other.phone
        email       = other.email
        url         = other.url
        notes       = other.notes
        applePlaceID   = other.applePlaceID
        applePhone     = other.applePhone
        appleURL       = other.appleURL
        appleFetchedAt = other.appleFetchedAt
        updatedAt   = Date()
    }
    
    func isContentEqual(_ other: PlaceUIModel) -> Bool {
        guard id == other.id else { return false }
        guard name == other.name else { return false }
        guard coordinates == other.coordinates else { return false }
        guard address == other.address else { return false }
        guard address2 == other.address2 else { return false }
        guard tags.map({ $0.id }) == other.tags.map({ $0.id }) else { return false }
        guard category.map({ $0.id }) == other.category.map({ $0.id }) else { return false }
        guard icon == other.icon else { return false }
        guard rating == other.rating else { return false }
        guard phone == other.phone else { return false }
        guard email == other.email else { return false }
        guard url == other.url else { return false }
        guard notes == other.notes else { return false }
        guard applePlaceID == other.applePlaceID else { return false }
        guard applePhone == other.applePhone else { return false }
        guard appleURL == other.appleURL else { return false }
        guard appleFetchedAt == other.appleFetchedAt else { return false }
        let selfDbIds = Set(images.compactMap(\.dbId))
        let otherDbIds = Set(other.images.compactMap(\.dbId))
        let hasPending = images.contains { $0.dbId == nil }
        guard selfDbIds == otherDbIds && !hasPending else { return false }
        return true
    }
}
