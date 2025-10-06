//
//  GroupMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

public enum GroupMapper {
    
    static func toDomain(_ sdGroup: SDGroup) -> GroupEntity {
        return GroupEntity(id: sdGroup.identifier,
                           name: sdGroup.name,
                           places: sdGroup.places.map { PlaceMapper.toDomain($0) },
                           color: sdGroup.color,
                           creationDate: sdGroup.creationDate)
    }
    
    static func toData(_ group: GroupEntity) -> SDGroup {
        return SDGroup(identifier: group.id,
                       name: group.name,
                       color: group.color)
    }
}
