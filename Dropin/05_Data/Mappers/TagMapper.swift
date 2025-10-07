//
//  TagMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

public enum TagMapper {
    
    static func toDomain(_ sdTag: SDTag, skipRelationships: Bool = false) -> TagEntity {
        var places = [PlaceEntity]()
        if !skipRelationships {
            if let tagPlaces = sdTag.places {
                places = tagPlaces.map { PlaceMapper.toDomain($0, skipRelationships: true) }
            }
        }
        let tag = TagEntity(id: sdTag.identifier,
                            name: sdTag.name,
                            color: sdTag.color,
                            places: places,
                            creationDate: sdTag.creationDate)
        if !skipRelationships {
            for i in 0..<places.count {
                places[i].tags.append(tag)
            }
        }
        return tag
    }
    
    static func toData(_ tag: TagEntity) -> SDTag {
        return SDTag(identifier: tag.id,
                     name: tag.name,
                     color: tag.color,
                     places: [],  // places are attached later in repository to avoid Mapping recursion 
                     creationDate: tag.creationDate)
    }
}
