//
//  TagMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

public enum TagMapper {
    
    static func toDomain(_ sdTag: SDTag) -> TagEntity {
        let tag = TagEntity(id: sdTag.identifier,
                            name: sdTag.name,
                            color: sdTag.color,
                            createdAt: sdTag.createdAt,
                            updatedAt: sdTag.updatedAt,
                            deletedAt: sdTag.deletedAt)
        return tag
    }
    
    static func toData(_ tag: TagEntity) -> SDTag {
        let sd = SDTag(identifier: tag.id,
                       name: tag.name,
                       color: tag.color)
        // SDTag.init hardcodes fresh dates; preserve domain timestamps so
        // server-originated rows (incl. soft-deletes) survive a pull.
        sd.createdAt = tag.createdAt
        sd.updatedAt = tag.updatedAt
        sd.deletedAt = tag.deletedAt
        return sd
    }
}
