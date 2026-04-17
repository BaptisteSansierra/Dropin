//
//  GroupMapper+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import Foundation

@MainActor
extension GroupMapper {

    static func toUI(_ group: GroupEntity, placeCount: Int) -> GroupUI {
        let groupUI = toUI(group)
        groupUI.placeCount = placeCount
        return groupUI
    }

    static func toUI(_ group: GroupEntity) -> GroupUI {
        let groupUI = GroupUI(id: group.id,
                              name: group.name,
                              color: group.color,
                              icon: group.icon,
                              places: [],
                              createdAt: group.createdAt,
                              deletedAt: group.deletedAt)
        return groupUI
    }
    
    static func toDomain(_ groupUI: GroupUI) -> GroupEntity {
        let group = GroupEntity(id: groupUI.id,
                                name: groupUI.name,
                                color: groupUI.color.hex,
                                icon: groupUI.icon,
                                createdAt: groupUI.createdAt,
                                deletedAt: groupUI.deletedAt)
        return group
    }
}
