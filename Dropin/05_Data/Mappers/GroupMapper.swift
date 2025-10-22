//
//  GroupMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

public enum GroupMapper {
    
    static func toDomain(_ sdGroup: SDGroup, skipRelationships: Bool = false) -> GroupEntity {
        var places = [PlaceEntity]()
        if !skipRelationships {
            places = sdGroup.places.map { PlaceMapper.toDomain($0, skipRelationships: true) }
        }
        let group = GroupEntity(id: sdGroup.identifier,
                                name: sdGroup.name,
                                places: places,
                                color: sdGroup.color,
                                creationDate: sdGroup.creationDate)
        if !skipRelationships {
            for i in 0..<places.count {
                places[i].group = group
            }
        }
        return group
    }
    
    static func toData(_ group: GroupEntity) -> SDGroup {
        return SDGroup(identifier: group.id,
                       name: group.name,
                       color: group.color)
    }
}
