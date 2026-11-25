//
//  SpaceMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/26.
//

import Foundation

public enum SpaceMapper {

    static func toDomain(_ sdSpace: SpaceRecord) -> Space {
        Space(id: sdSpace.identifier,
             name: sdSpace.name,
             color: sdSpace.color,
             icon: sdSpace.icon,
             ownerId: sdSpace.ownerId,
             createdAt: sdSpace.createdAt,
             updatedAt: sdSpace.updatedAt,
             deletedAt: sdSpace.deletedAt)
    }

    static func toData(_ space: Space) -> SpaceRecord {
        let sd = SpaceRecord(identifier: space.id,
                             name: space.name,
                             color: space.color,
                             icon: space.icon,
                             ownerId: space.ownerId)
        // SpaceRecord.init hardcodes fresh dates; preserve domain timestamps so
        // server-originated rows survive a pull.
        sd.createdAt = space.createdAt
        sd.updatedAt = space.updatedAt
        sd.deletedAt = space.deletedAt
        return sd
    }
}
