//
//  PlaceMapper+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import Foundation

@MainActor
extension PlaceMapper {
    
    static func toUI(_ place: PlaceEntity, skipRelationships: Bool = false) -> PlaceUI {
        var groupUI: GroupUI? = nil
        var tagsUI = [TagUI]()
        if !skipRelationships {
            tagsUI = place.tags.map { TagMapper.toUI($0, skipRelationships: true) }
            if let group = place.group {
                groupUI = GroupMapper.toUI(group, skipRelationships: true)
            }
        }
        let placeUI = PlaceUI(id: place.id,
                              name: place.name,
                              coordinates: place.coordinates,
                              address: place.address,
                              systemImage: place.systemImage,
                              tags: tagsUI,
                              group: groupUI,
                              notes: place.notes,
                              phone: place.phone,
                              url: place.url,
                              creationDate: place.creationDate,
                              databaseDeleted: place.databaseDeleted)
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
            tags = placeUI.tags.map { TagMapper.toDomain($0, skipRelationships: true) }
            if let groupUI = placeUI.group {
                group = GroupMapper.toDomain(groupUI, skipRelationships: true)
            }
        }
        let place = PlaceEntity(id: placeUI.id,
                                name: placeUI.name,
                                coordinates: placeUI.coordinates,
                                address: placeUI.address,
                                systemImage: placeUI.systemImage,
                                tags: tags,
                                group: group,
                                notes: placeUI.notes,
                                phone: placeUI.phone,
                                url: placeUI.url,
                                creationDate: placeUI.creationDate,
                                databaseDeleted: placeUI.databaseDeleted)
        if !skipRelationships {
            group?.places.append(place)
            for i in 0..<tags.count {
                tags[i].places.append(place)
            }
        }
        return place
    }
}
