//
//  SpaceMapper+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/26.
//

import Foundation

@MainActor
extension SpaceMapper {

    static func toUI(_ space: Space) -> SpaceUIModel {
        SpaceUIModel(id: space.id,
                     name: space.name,
                     color: space.color,
                     icon: space.icon,
                     ownerId: space.ownerId,
                     createdAt: space.createdAt,
                     updatedAt: space.updatedAt,
                     deletedAt: space.deletedAt)
    }

    static func toDomain(_ spaceUI: SpaceUIModel) -> Space {
        Space(id: spaceUI.id,
              name: spaceUI.name,
              color: spaceUI.color.hex,
              icon: spaceUI.icon,
              ownerId: spaceUI.ownerId,
              createdAt: spaceUI.createdAt,
              updatedAt: spaceUI.updatedAt,
              deletedAt: spaceUI.deletedAt)
    }
}
