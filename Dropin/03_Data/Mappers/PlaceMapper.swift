//
//  PlaceMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import CoreLocation

public enum PlaceMapper {
    
    static func toDomain(_ sdPlace: SDPlace, skipRelationships: Bool = false) -> PlaceEntity {
        var group: GroupEntity? = nil
        var tags = [TagEntity]()
        if !skipRelationships {
            tags = sdPlace.tags.map { TagMapper.toDomain($0) }
            if let sdGroup = sdPlace.group {
                group = GroupMapper.toDomain(sdGroup)
            }
        }
        let place = PlaceEntity(id: sdPlace.identifier,
                                name: sdPlace.name,
                                coordinates: CLLocationCoordinate2D(latitude: sdPlace.latitude, longitude: sdPlace.longitude),
                                address: sdPlace.address,
                                address2: sdPlace.address2,
                                tags: tags,
                                group: group,
                                icon: sdPlace.icon,
                                rating: sdPlace.rating,
                                phone: sdPlace.phone,
                                email: sdPlace.email,
                                url: sdPlace.url,
                                notes: sdPlace.notes,
                                images: sdPlace.images,
                                createdAt: sdPlace.createdAt,
                                deletedAt: sdPlace.deletedAt)
        return place
    }
    
    static func toData(_ place: PlaceEntity) -> SDPlace {
        return SDPlace(identifier: place.id,
                       name: place.name,
                       latitude: place.coordinates.latitude,
                       longitude: place.coordinates.longitude,
                       address: place.address,
                       address2: place.address2,
                       tags: [SDTag](),
                       group: nil,
                       icon: place.icon,
                       rating: place.rating,
                       phone: place.phone,
                       email: place.email,
                       url: place.url,
                       notes: place.notes,
                       images: place.images)
    }
}
