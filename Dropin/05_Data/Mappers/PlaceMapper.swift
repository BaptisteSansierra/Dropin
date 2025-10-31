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
//        var groupId: String?
//        if let group = sdPlace.group {
//            groupId = group.identifier
//        }
        var group: GroupEntity? = nil
        var tags = [TagEntity]()
        if !skipRelationships {
            tags = sdPlace.tags.map { TagMapper.toDomain($0, skipRelationships: true) }
            if let sdGroup = sdPlace.group {
                group = GroupMapper.toDomain(sdGroup, skipRelationships: true)
            }
        }
        let place = PlaceEntity(id: sdPlace.identifier,
                                name: sdPlace.name,
                                coordinates: CLLocationCoordinate2D(latitude: sdPlace.latitude, longitude: sdPlace.longitude),
                                address: sdPlace.address,
                                tags: tags,
                                group: group,
                                sfSymbol: sdPlace.sfSymbol,
                                notes: sdPlace.notes,
                                phone: sdPlace.phone,
                                url: sdPlace.url,
                                creationDate: sdPlace.creationDate)
        //place.groupColor = sdPlace.group?.color
        // Relationships were created but not linked, do it manually
        if !skipRelationships {
            group?.places.append(place)
            for i in 0..<tags.count {
                tags[i].places.append(place)
            }
        }
        return place
    }
    
    static func toData(_ place: PlaceEntity) -> SDPlace {
        return SDPlace(identifier: place.id,
                       name: place.name,
                       latitude: place.coordinates.latitude,
                       longitude: place.coordinates.longitude,
                       address: place.address,
                       tags: [SDTag](),
                       group: nil,
                       sfSymbol: place.sfSymbol,
                       notes: place.notes,
                       phone: place.phone,
                       url: place.url)
    }
}
