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
    let deletedAt: Date?
    // Note: places are not strores here to avoid bidirectional relationships
    // PlaceEntity owns the relationship

    init(id: UUID, name: String, color: String, createdAt: Date, deletedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
    
    init(name: String, color: String) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
        self.deletedAt = nil
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
