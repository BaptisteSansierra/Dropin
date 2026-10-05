//
//  SupabasePlaceDTO.swift
//  Dropin

import Foundation
import CoreLocation

struct SupabasePlaceDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
    let address2: String?
    let categoryId: UUID?
    let tagIds: [UUID]
    let icon: String?
    let rating: Float?
    let phone: [String]
    let email: [String]
    let url: [String]
    let notes: String?
    let imageIds: [UUID]
    let applePlaceID: String?
    let applePhone: String?
    let appleURL: String?
    let appleFetchedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case name
        case latitude
        case longitude
        case address
        case address2
        case categoryId   = "category_id"
        case tagIds    = "tag_ids"
        case icon
        case rating
        case phone
        case email
        case url
        case notes
        case imageIds  = "image_ids"
        case applePlaceID   = "apple_place_id"
        case applePhone     = "apple_phone"
        case appleURL       = "apple_url"
        case appleFetchedAt = "apple_fetched_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    /// Explicit encoder — synthesized Codable uses `encodeIfPresent` for Optionals, which
    /// drops nil keys entirely. Postgrest's `upsert` then leaves those columns untouched,
    /// so e.g. clearing `place.category` silently fails to nullify `group_id` server-side.
    /// Using `encode` writes the key with JSON `null`, which is what we want.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(userId,    forKey: .userId)
        try c.encode(name,      forKey: .name)
        try c.encode(latitude,  forKey: .latitude)
        try c.encode(longitude, forKey: .longitude)
        try c.encode(address,   forKey: .address)
        try c.encode(address2,  forKey: .address2)
        try c.encode(categoryId,   forKey: .categoryId)
        try c.encode(tagIds,    forKey: .tagIds)
        try c.encode(icon,      forKey: .icon)
        try c.encode(rating,    forKey: .rating)
        try c.encode(phone,     forKey: .phone)
        try c.encode(email,     forKey: .email)
        try c.encode(url,       forKey: .url)
        try c.encode(notes,     forKey: .notes)
        try c.encode(imageIds,  forKey: .imageIds)
        try c.encode(applePlaceID,   forKey: .applePlaceID)
        try c.encode(applePhone,     forKey: .applePhone)
        try c.encode(appleURL,       forKey: .appleURL)
        try c.encode(appleFetchedAt, forKey: .appleFetchedAt)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(deletedAt, forKey: .deletedAt)
    }

    init(from place: Place, userId: UUID) {
        self.id        = place.id
        self.userId    = userId
        self.name      = place.name
        self.latitude  = place.coordinates.latitude
        self.longitude = place.coordinates.longitude
        self.address   = place.address
        self.address2  = place.address2
        self.categoryId   = place.category?.id
        self.tagIds    = place.tags.map(\.id)
        self.icon      = place.icon?.rawValue
        self.rating    = place.rating
        self.phone     = place.phone
        self.email     = place.email
        self.url       = place.url
        self.notes     = place.notes
        self.imageIds  = place.images
        self.applePlaceID   = place.applePlaceID
        self.applePhone     = place.applePhone
        self.appleURL       = place.appleURL
        self.appleFetchedAt = place.appleFetchedAt
        self.createdAt = place.createdAt
        self.updatedAt = place.updatedAt
        self.deletedAt = place.deletedAt
    }

    func toDomain() -> Place {
        // Tags and category are resolved from tag_ids/group_id via stubs.
        // PlaceRepositoryImpl.upsert uses only the .id from each entity
        // to look up the real TagRecord/CategoryRecord objects in SwiftData.
        // Tags and categories must be synced before places for linkage to succeed.
        let stubTags = tagIds.map { id in
            Tag(id: id, name: "", color: "000000",
                      createdAt: .distantPast, updatedAt: .distantPast, deletedAt: nil)
        }
        let stubCategory = categoryId.map { id in
            Category(id: id, name: "", color: "000000", icon: .sf(""),
                        createdAt: .distantPast, updatedAt: .distantPast, deletedAt: nil)
        }
        return Place(
            id: id, name: name,
            coordinates: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            address: address, address2: address2,
            tags: stubTags, category: stubCategory,
            images: imageIds,
            icon: icon.flatMap { Icon(rawValue: $0) },
            rating: rating,
            phone: phone, email: email, url: url, notes: notes,
            applePlaceID: applePlaceID, applePhone: applePhone,
            appleURL: appleURL, appleFetchedAt: appleFetchedAt,
            createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt
        )
    }
}
