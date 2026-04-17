//
//  TagMapper+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import Foundation

@MainActor
extension TagMapper {
    
    static func toUI(_ tag: TagEntity, placeCount: Int) -> TagUI {
        let tagUI = toUI(tag)
        tagUI.placeCount = placeCount
        return tagUI
    }

    static func toUI(_ tag: TagEntity, skipRelationships: Bool = false) -> TagUI {
        let tagUI = TagUI(id: tag.id,
                          name: tag.name,
                          color: tag.color,
                          places: [],
                          createdAt: tag.createdAt,
                          deletedAt: tag.deletedAt)
        return tagUI
    }
    
    static func toDomain(_ tagUI: TagUI) -> TagEntity {
        let tag = TagEntity(id: tagUI.id,
                            name: tagUI.name,
                            color: tagUI.color.hex,
                            createdAt: tagUI.createdAt,
                            deletedAt: tagUI.deletedAt)
        return tag
    }
}
