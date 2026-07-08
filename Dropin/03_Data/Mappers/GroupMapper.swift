//
//  GroupMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

public enum GroupMapper {
    
    static func toDomain(_ sdGroup: SDGroup) -> GroupEntity {
        let group = GroupEntity(id: sdGroup.identifier,
                                name: sdGroup.name,
                                color: sdGroup.color,
                                icon: sdGroup.icon,
                                createdAt: sdGroup.createdAt,
                                updatedAt: sdGroup.updatedAt,
                                deletedAt: sdGroup.deletedAt)
        return group
    }
    
    static func toData(_ group: GroupEntity) -> SDGroup {
        let sd = SDGroup(identifier: group.id,
                         name: group.name,
                         color: group.color,
                         icon: group.icon)
        // SDGroup.init hardcodes fresh dates; preserve domain timestamps so
        // server-originated rows (incl. soft-deletes) survive a pull.
        sd.createdAt = group.createdAt
        sd.updatedAt = group.updatedAt
        sd.deletedAt = group.deletedAt
        return sd
    }
}
