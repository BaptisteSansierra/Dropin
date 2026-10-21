//
//  Space.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/26.
//

import Foundation

struct Space: Hashable, Sendable {
    
    /// Well-known fixed id representing the user's personal, implicit space (not a stored SpaceRecord).
    /// Every other Space is a real, named, shareable, stored entity.
    /// See PlaceRecord/CategoryRecord/TagRecord's `spaceId` and SpaceContext.
    static let mainId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    let id: UUID
    let name: String
    let color: String
    let icon: Icon
    var ownerId: UUID
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    // Used by mappers
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
        self.color = color
        self.icon = icon
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    func deleted(deletedAt: Date) -> Space {
        var copy = self
        copy.deletedAt = deletedAt
        return copy
    }

    func updated() -> Space {
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

extension Space {
    var isActive: Bool { deletedAt == nil }
}
