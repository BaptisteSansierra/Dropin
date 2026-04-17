//
//  TagUI.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI

@MainActor
@Observable class TagUI: Identifiable, @MainActor Equatable {
//@MainActor
//struct TagUI: Identifiable, @MainActor Equatable {

    let id: UUID
    var name: String
    var color: Color
    var places: [PlaceUI] = [PlaceUI]()
    var createdAt: Date
    var deletedAt: Date? = nil

    var isActive: Bool {
        deletedAt == nil
    }
    
    static func == (lhs: TagUI, rhs: TagUI) -> Bool {
        lhs.id == rhs.id
    }

    init(id: UUID, name: String, color: String, places: [PlaceUI], createdAt: Date, deletedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.color = Color(rgba: color)
        self.places = places
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
    
//    init(name: String, color: String) {
//        self.id = UUID().uuidString
//        self.name = name
//        self.color = color
//        createdAt = Date()
//    }
}
