//
//  PlaceMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import CoreLocation

public enum PlaceMapper {
    
    static func toDomain(_ sdPlace: PlaceRecord, skipRelationships: Bool = false) -> Place {
        var category: Category? = nil
        var tags = [Tag]()
        if !skipRelationships {
            tags = sdPlace.tags
                .filter { $0.deletedAt == nil }  // Ignore deleted tags
                .map { TagMapper.toDomain($0) }
            if let sdCategory = sdPlace.category, sdCategory.deletedAt == nil {
                category = CategoryMapper.toDomain(sdCategory)
            }
        }
        let place = Place(id: sdPlace.identifier,
                          name: sdPlace.name,
                          coordinates: CLLocationCoordinate2D(latitude: sdPlace.latitude, longitude: sdPlace.longitude),
                          address: sdPlace.address,
                          address2: sdPlace.address2,
                          tags: tags,
                          category: category,
                          images: sdPlace.images.map(\.id),
                          icon: sdPlace.icon,
                          rating: sdPlace.rating,
                          phone: sdPlace.phone,
                          email: sdPlace.email,
                          url: sdPlace.url,
                          notes: sdPlace.notes,
                          applePlaceID: sdPlace.applePlaceID,
                          appleNotFoundAt: sdPlace.appleNotFoundAt,
                          createdAt: sdPlace.createdAt,
                          updatedAt: sdPlace.updatedAt,
                          deletedAt: sdPlace.deletedAt)
        return place
    }
    
    static func toData(_ place: Place) -> PlaceRecord {
        let sd = PlaceRecord(identifier: place.id,
                         name: place.name,
                         latitude: place.coordinates.latitude,
                         longitude: place.coordinates.longitude,
                         address: place.address,
                         address2: place.address2,
                         tags: [TagRecord](),
                         category: nil,
                         images: [],
                         icon: place.icon,
                         rating: place.rating,
                         phone: place.phone,
                         email: place.email,
                         url: place.url,
                         notes: place.notes,
                         applePlaceID: place.applePlaceID,
                         appleNotFoundAt: place.appleNotFoundAt)
        // PlaceRecord.init always stamps fresh dates ("now") and nil deletedAt.
        // Overwrite with the domain values so server-originated timestamps
        // (and soft-delete markers) are preserved across pulls.
        sd.createdAt = place.createdAt
        sd.updatedAt = place.updatedAt
        sd.deletedAt = place.deletedAt
        return sd
    }
}
