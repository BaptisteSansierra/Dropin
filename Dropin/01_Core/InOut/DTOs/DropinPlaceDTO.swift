//
//  DropinPlaceDTO.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/4/26.
//

import Foundation
import CoreLocation

/// .dropin wire format for a place.
/// Carries no id and no dates: the importer assigns a fresh identity (cf. ImportDropinService).
/// Relationships refer to the file-local ids of DropinTagDTO / DropinCategoryDTO.
struct DropinPlaceDTO: Codable, Sendable {

    var name: String
    var coordinates: CLLocationCoordinate2D
    var address: String?
    var address2: String?
    var tagIds: [UUID]
    var categoryId: UUID?
    var icon: Icon?
    var rating: Float?
    var phone: [String]
    var email: [String]
    var url: [String]
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name
        case coordinates
        case address
        case address2
        case tagIds
        case categoryId
        case icon
        case rating
        case phone
        case email
        case url
        case notes
    }

    init(_ place: Place) {
        self.name = place.name
        self.coordinates = place.coordinates
        self.address = place.address
        self.address2 = place.address2
        self.tagIds = place.tags.map { $0.id }
        self.categoryId = place.category?.id
        self.icon = place.icon
        self.rating = place.rating
        self.phone = place.phone
        self.email = place.email
        self.url = place.url
        self.notes = place.notes
    }

    /// Creates a new domain place: fresh id, every date set to `importDate`
    func toDomain(tags: [Tag], category: Category?, importDate: Date) -> Place {
        Place(id: UUID(),
              name: name,
              coordinates: coordinates,
              address: address,
              address2: address2,
              tags: tags,
              category: category,
              images: [],  // Not supported
              icon: icon,
              rating: rating,
              phone: phone,
              email: email,
              url: url,
              notes: notes,
              createdAt: importDate,
              updatedAt: importDate,
              deletedAt: nil,
              importedAt: importDate,
              importSrc: .dropin)
    }
}
