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
                            deletedAt: sdTag.deletedAt,
                            importedAt: sdTag.importedAt,
                            importSrc: sdTag.importSrc.flatMap(ImportSource.init(rawValue:)),
                            spaceId: sdTag.spaceId)
        return tag
    }

    /// `spaceId` is explicit, resolved by the repository (never read off `tag.spaceId`,
    /// which is nil for anything not yet persisted).
    /// cf. TagRepositoryImpl.upsert(_:spaceId:shouldSave:).
    static func toData(_ tag: Tag, spaceId: UUID) -> TagRecord {
        let sd = TagRecord(identifier: tag.id,
                       spaceId: spaceId,
                       name: tag.name,
                       color: tag.color)
        // TagRecord.init hardcodes fresh dates; preserve domain timestamps so
        // server-originated rows (incl. soft-deletes) survive a pull.
        sd.createdAt = tag.createdAt
        sd.updatedAt = tag.updatedAt
        sd.deletedAt = tag.deletedAt
        sd.importedAt = tag.importedAt
        sd.importSrc = tag.importSrc?.rawValue
        return sd
    }
}
