//
//  Tag.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct TagEntity: Hashable, Sendable {
    let id: UUID
    let name: String
    let color: String
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    // Note: places are not stored here to avoid bidirectional relationships
    // PlaceEntity owns the relationship

    // Used by mappers
    init(id: UUID,
         name: String,
         color: String,
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date?) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
    
    init(name: String, color: String) {
        self.id = UUID()
        self.name = name
        self.color = color
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
    }
    
    func deleted(deletedAt: Date) -> TagEntity {
        var copy = self
        copy.deletedAt = nil
        return copy
    }

    func undeleted() -> TagEntity {
        var copy = self
        copy.deletedAt = nil
        return copy
    }
    
    func updated() -> TagEntity {
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
