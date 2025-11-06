//
//  GroupEntity+Extension.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
@testable import Dropin

extension GroupEntity {  // Mock extension
    static func mockGroups() -> [GroupEntity] {
        let g1 = GroupEntity(name: "Restaurant", color: "9944AA", icon: Icon("sf:tag"))
        let g2 = GroupEntity(name: "Bar", color: "CC22AA", icon: Icon("sf:tag"))
        let g3 = GroupEntity(name: "Trekking", color: "FF9999", icon: Icon("sf:tag"))
        let g4 = GroupEntity(name: "Fishing spot", color: "456699", icon: Icon("sf:tag"))
        let g5 = GroupEntity(name: "Amusement", color: "DD8855", icon: Icon("sf:tag"))
        let g6 = GroupEntity(name: "Disco", color: "7788CC", icon: Icon("sf:tag"))
        let g7 = GroupEntity(name: "Culture", color: "2255DD", icon: Icon("sf:tag"))
        let g8 = GroupEntity(name: "Shop", color: "FF6600", icon: Icon("sf:tag"))
        let g9 = GroupEntity(name: "Body health", color: "4dd333", icon: Icon("sf:tag"))
        let g10 = GroupEntity(name: "Laundry", color: "334dd3", icon: Icon("sf:tag"))
        return [g1, g2, g3, g4, g5, g6, g7, g8, g9, g10]
    }
}
