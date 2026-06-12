//
//  GroupEntity.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct GroupEntity: Hashable, Sendable {
    let id: UUID
    let name: String
    let icon: Icon
    let color: String
    let createdAt: Date
    var updatedAt: Date
    let deletedAt: Date?
    // Note: places are not strores here to avoid bidirectional relationships
    // PlaceEntity owns the relationship

    // Used by mappers
    init(id: UUID,
         name: String,
         color: String,
         icon: Icon,
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date?) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
    
    init(name: String, color: String, icon: Icon) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        let now = Date()
        createdAt = now
        updatedAt = now
        deletedAt = nil
    }
    
    func updated() -> GroupEntity {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
