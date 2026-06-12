//
//  GroupUI.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI

@MainActor
@Observable class GroupUI: Identifiable {

    let id: UUID
    var name: String
    var icon: Icon
    var color: Color
    var places: [PlaceUI]
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    // used to get place count when places are not populated
    var placeCount: Int = -1

    var isActive: Bool {
        deletedAt == nil
    }

    init(id: UUID,
         name: String,
         color: String,
         icon: Icon,
         places: [PlaceUI],
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date?) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = Color(rgba: color)
        self.places = places
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
    
    #if DEBUG
    init(color: String) {
        self.id = UUID()
        self.name = "RANDOM"
        self.icon = Icon(sf: "infinity.circle")!
        self.color = Color(rgba: color)
        self.places = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
    }
    #endif
}
