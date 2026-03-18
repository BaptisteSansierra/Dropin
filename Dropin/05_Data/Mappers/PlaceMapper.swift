//
//  PlaceMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import CoreLocation
import ContactFieldKit

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
        let phones = sdPlace.phone
            .filter { ContactItem(rawValue: $0) != nil }
            .map { ContactItem(rawValue: $0)! }
        let emails = sdPlace.email
            .filter { ContactItem(rawValue: $0) != nil }
            .map { ContactItem(rawValue: $0)! }
        let urls = sdPlace.url
            .filter { ContactItem(rawValue: $0) != nil }
            .map { ContactItem(rawValue: $0)! }
        let place = PlaceEntity(id: sdPlace.identifier,
                                name: sdPlace.name,
                                coordinates: CLLocationCoordinate2D(latitude: sdPlace.latitude, longitude: sdPlace.longitude),
                                address: sdPlace.address,
                                address2: sdPlace.address2,
                                tags: tags,
                                group: group,
                                icon: sdPlace.icon,
                                rating: sdPlace.rating,
                                phone: phones,
                                email: emails,
                                url: urls,
                                notes: sdPlace.notes,
                                images: sdPlace.images,
                                creationDate: sdPlace.creationDate,
                                deletionDate: sdPlace.deletionDate)
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
                       address2: place.address2,
                       tags: [SDTag](),
                       group: nil,
                       icon: place.icon,
                       rating: place.rating,
                       phone: place.phone.map { $0.rawValue },
                       email: place.email.map { $0.rawValue },
                       url: place.url.map { $0.rawValue },
                       notes: place.notes,
                       images: place.images)
    }
}
