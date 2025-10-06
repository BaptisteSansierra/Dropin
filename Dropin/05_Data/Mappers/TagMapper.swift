//
//  TagMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

public enum TagMapper {
    
    static func toDomain(_ sdTag: SDTag) -> TagEntity {
        var places = [PlaceEntity]()
        if let tagPlaces = sdTag.places {
            places = tagPlaces.map { PlaceMapper.toDomain($0) }
        }
        return TagEntity(id: sdTag.identifier,
                         name: sdTag.name,
                         color: sdTag.color,
                         places: places,
                         creationDate: sdTag.creationDate)
    }
    
    static func toData(_ tag: TagEntity) -> SDTag {
        return SDTag(identifier: tag.id,
                     name: tag.name,
                     color: tag.color,
                     places: [],  // places are attached later in repository to avoid Mapping recursion 
                     creationDate: tag.creationDate)
    }
}
