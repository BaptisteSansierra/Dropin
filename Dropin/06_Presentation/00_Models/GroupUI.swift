//
//  GroupUI.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI

@MainActor
@Observable class GroupUI: Identifiable, @MainActor Equatable {

    let id: UUID
    var name: String
    var icon: Icon
    var color: Color
    var places: [PlaceUI] = [PlaceUI]()
    var creationDate: Date
    var deletionDate: Date? = nil
    
    var isActive: Bool {
        deletionDate == nil
    }
    
    static func == (lhs: GroupUI, rhs: GroupUI) -> Bool {
        lhs.id == rhs.id
    }

    init(id: UUID, name: String, color: String, icon: Icon, places: [PlaceUI], creationDate: Date, deletionDate: Date? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = Color(rgba: color)
        self.places = places
        self.creationDate = creationDate
        self.deletionDate = deletionDate
    }
    
//    init(name: String, color: String) {
//        self.id = UUID().uuidString
//        self.name = name
//        self.color = color
//        creationDate = Date()
//    }
}
