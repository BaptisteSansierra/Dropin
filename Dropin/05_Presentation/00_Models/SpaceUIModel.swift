//
//  SpaceUIModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/26.
//

import SwiftUI

@MainActor
@Observable class SpaceUIModel: Identifiable {

    let id: UUID
    var name: String
    var icon: Icon
    var color: Color
    var ownerId: UUID
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var isActive: Bool {
        deletedAt == nil
    }

    init(id: UUID,
         name: String,
         color: String,
         icon: Icon,
         ownerId: UUID,
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date?) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = Color(rgba: color)
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
