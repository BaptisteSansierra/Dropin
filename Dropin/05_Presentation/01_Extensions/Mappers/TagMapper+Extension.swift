//
//  TagMapper+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import Foundation

@MainActor
extension TagMapper {
    
    static func toUI(_ tag: Tag, placeCount: Int) -> TagUIModel {
        let tagUI = toUI(tag)
        tagUI.placeCount = placeCount
        return tagUI
    }

    static func toUI(_ tag: Tag, skipRelationships: Bool = false) -> TagUIModel {
        let tagUI = TagUIModel(id: tag.id,
                          name: tag.name,
                          color: tag.color,
                          places: [],
                          createdAt: tag.createdAt,
                          updatedAt: tag.updatedAt,
                          deletedAt: tag.deletedAt)
        return tagUI
    }
    
    static func toDomain(_ tagUI: TagUIModel) -> Tag {
        let tag = Tag(id: tagUI.id,
                            name: tagUI.name,
                            color: tagUI.color.hex,
                            createdAt: tagUI.createdAt,
                            updatedAt: tagUI.updatedAt,
                            deletedAt: tagUI.deletedAt)
        return tag
    }
}
