//
//  PlaceMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import CoreLocation

public enum PlaceMapper {
    
    static func toDomain(_ sdPlace: SDPlace) -> PlaceEntity {
        var groupId: String?
        if let group = sdPlace.group {
            groupId = group.identifier
        }
        var place = PlaceEntity(id: sdPlace.identifier,
                                name: sdPlace.name,
                                coordinates: CLLocationCoordinate2D(latitude: sdPlace.latitude, longitude: sdPlace.longitude),
                                address: sdPlace.address,
                                systemImage: sdPlace.systemImage,
                                tagIds: sdPlace.tags.map {$0.identifier},
                                groupId: groupId,
                                notes: sdPlace.notes,
                                phone: sdPlace.phone,
                                url: sdPlace.url,
                                creationDate: sdPlace.creationDate)
        place.groupColor = sdPlace.group?.color
        return place
    }
    
    static func toData(_ place: PlaceEntity) -> SDPlace {
        return SDPlace(identifier: place.id,
                       name: place.name,
                       latitude: place.coordinates.latitude,
                       longitude: place.coordinates.longitude,
                       address: place.address,
                       systemImage: place.systemImage,
                       tags: [SDTag](),
                       group: nil,
                       notes: place.notes,
                       phone: place.phone,
                       url: place.url)
    }
}
