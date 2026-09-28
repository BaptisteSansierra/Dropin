//
//  TagMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

public enum TagMapper {
    
    static func toDomain(_ sdTag: TagRecord) -> Tag {
        let tag = Tag(id: sdTag.identifier,
                            name: sdTag.name,
                            color: sdTag.color,
                            createdAt: sdTag.createdAt,
                            updatedAt: sdTag.updatedAt,
                            deletedAt: sdTag.deletedAt)
        return tag
    }
    
    static func toData(_ tag: Tag) -> TagRecord {
        let sd = TagRecord(identifier: tag.id,
                       name: tag.name,
                       color: tag.color)
        // TagRecord.init hardcodes fresh dates; preserve domain timestamps so
        // server-originated rows (incl. soft-deletes) survive a pull.
        sd.createdAt = tag.createdAt
        sd.updatedAt = tag.updatedAt
        sd.deletedAt = tag.deletedAt
        return sd
    }
}
