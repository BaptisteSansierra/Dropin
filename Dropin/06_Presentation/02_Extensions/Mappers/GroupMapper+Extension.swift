//
//  GroupMapper+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import Foundation

@MainActor
extension GroupMapper {
    
    static func toUI(_ group: GroupEntity, skipRelationships: Bool = false) -> GroupUI {
        var placesUI = [PlaceUI]()
        if !skipRelationships {
            placesUI = group.places.map { PlaceMapper.toUI($0, skipRelationships: true) }
        }
        let groupUI = GroupUI(id: group.id,
                              name: group.name,
                              color: group.color,
                              sfSymbol: group.sfSymbol,
                              places: placesUI,
                              creationDate: group.creationDate,
                              databaseDeleted: group.databaseDeleted)
        if !skipRelationships {
            for i in 0..<placesUI.count {
                placesUI[i].group = groupUI
            }
        }
        return groupUI
    }
    
    static func toDomain(_ groupUI: GroupUI, skipRelationships: Bool = false) -> GroupEntity {
        var places = [PlaceEntity]()
        if !skipRelationships {
            places = groupUI.places.map { PlaceMapper.toDomain($0, skipRelationships: true) }
        }
        let group = GroupEntity(id: groupUI.id,
                                name: groupUI.name,
                                color: groupUI.color.hex,
                                sfSymbol: groupUI.sfSymbol,
                                places: places,
                                creationDate: groupUI.creationDate,
                                databaseDeleted: groupUI.databaseDeleted)
        if !skipRelationships {
            for i in 0..<places.count {
                places[i].group = group
            }
        }
        return group
    }
}
