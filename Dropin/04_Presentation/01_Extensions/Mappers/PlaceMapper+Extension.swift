//
//  PlaceMapper+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import Foundation
import ContactFieldKit

@MainActor
extension PlaceMapper {
    
    static func toUI(_ place: PlaceEntity, skipRelationships: Bool = false) -> PlaceUI {
        var groupUI: GroupUI? = nil
        var tagsUI = [TagUI]()
        if !skipRelationships {
            tagsUI = place.tags.map { TagMapper.toUI($0) }
            if let group = place.group {
                groupUI = GroupMapper.toUI(group)
            }
        }
        
        let phones = place.phone
            .filter { ContactItem(rawValue: $0) != nil }
            .map { ContactItem(rawValue: $0)! }
        let emails = place.email
            .filter { ContactItem(rawValue: $0) != nil }
            .map { ContactItem(rawValue: $0)! }
        let urls = place.url
            .filter { ContactItem(rawValue: $0) != nil }
            .map { ContactItem(rawValue: $0)! }
        
        let placeUI = PlaceUI(id: place.id,
                              name: place.name,
                              coordinates: place.coordinates,
                              address: place.address,
                              address2: place.address2,
                              tags: tagsUI,
                              group: groupUI,
                              icon: place.icon,
                              rating: place.rating,
                              phone: phones,
                              email: emails,
                              url: urls,
                              notes: place.notes,
                              images: place.images,
                              createdAt: place.createdAt,
                              deletedAt: place.deletedAt)
        if !skipRelationships {
            groupUI?.places.append(placeUI)
            for i in 0..<tagsUI.count {
                tagsUI[i].places.append(placeUI)
            }
        }
        return placeUI
    }
    
    static func toDomain(_ placeUI: PlaceUI, skipRelationships: Bool = false) -> PlaceEntity {
        var group: GroupEntity? = nil
        var tags = [TagEntity]()
        if !skipRelationships {
            tags = placeUI.tags.map { TagMapper.toDomain($0) }
            if let groupUI = placeUI.group {
                group = GroupMapper.toDomain(groupUI)
            }
        }
        let place = PlaceEntity(id: placeUI.id,
                                name: placeUI.name,
                                coordinates: placeUI.coordinates,
                                address: placeUI.address,
                                address2: placeUI.address2,
                                tags: tags,
                                group: group,
                                icon: placeUI.icon,
                                rating: placeUI.rating,
                                phone: placeUI.phone.map { $0.rawValue },
                                email: placeUI.email.map { $0.rawValue },
                                url: placeUI.url.map { $0.rawValue },
                                notes: placeUI.notes,
                                images: placeUI.images,
                                createdAt: placeUI.createdAt,
                                deletedAt: placeUI.deletedAt)
        return place
    }
}
