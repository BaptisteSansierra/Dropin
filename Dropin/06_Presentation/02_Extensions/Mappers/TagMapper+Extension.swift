//
//  TagMapper+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import Foundation

@MainActor
extension TagMapper {
    
    static func toUI(_ tag: TagEntity, skipRelationships: Bool = false) -> TagUI {
        var places = [PlaceUI]()
        if !skipRelationships {
            places = tag.places.map { PlaceMapper.toUI($0, skipRelationships: true) }
        }
        let tagUI = TagUI(id: tag.id,
                          name: tag.name,
                          color: tag.color,
                          places: places,
                          creationDate: tag.creationDate,
                          databaseDeleted: tag.databaseDeleted)
        if !skipRelationships {
            for i in 0..<places.count {
                places[i].tags.append(tagUI)
            }
        }
        return tagUI
    }
    
    static func toDomain(_ tagUI: TagUI, skipRelationships: Bool = false) -> TagEntity {
        var places = [PlaceEntity]()
        if !skipRelationships {
            places = tagUI.places.map { PlaceMapper.toDomain($0, skipRelationships: true) }
        }
        let tag = TagEntity(id: tagUI.id,
                            name: tagUI.name,
                            color: tagUI.color.hex,
                            places: places,
                            creationDate: tagUI.creationDate,
                            databaseDeleted: tagUI.databaseDeleted)
        if !skipRelationships {
            for i in 0..<places.count {
                places[i].tags.append(tag)
            }
        }
        return tag
    }
}
