//
//  TagUIModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI

@MainActor
@Observable class TagUIModel: Identifiable {

    let id: UUID
    var name: String
    var color: Color
    var places: [PlaceUIModel]
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
         places: [PlaceUIModel],
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date?) {
        self.id = id
        self.name = name
        self.color = Color(rgba: color)
        self.places = places
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
