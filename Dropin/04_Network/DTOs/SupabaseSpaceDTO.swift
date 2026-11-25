//
//  SupabaseSpaceDTO.swift
//  Dropin

import Foundation

struct SupabaseSpaceDTO: Codable {
    let id: UUID
    let name: String
    let color: String
    let icon: String
    let ownerId: UUID
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case icon
        case ownerId   = "owner_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    /// Explicit encode so `deleted_at: null` is sent over the wire. See SupabasePlaceDTO.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(name,      forKey: .name)
        try c.encode(color,     forKey: .color)
        try c.encode(icon,      forKey: .icon)
        try c.encode(ownerId,   forKey: .ownerId)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(deletedAt, forKey: .deletedAt)
    }

    init(from space: Space) {
        self.id        = space.id
        self.name      = space.name
        self.color     = space.color
        self.icon      = space.icon.rawValue
        self.ownerId   = space.ownerId
        self.createdAt = space.createdAt
        self.updatedAt = space.updatedAt
        self.deletedAt = space.deletedAt
    }

    func toDomain() -> Space {
        Space(id: id, name: name, color: color,
             icon: Icon(rawValue: icon) ?? .sf("questionmark"),
             ownerId: ownerId,
             createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt)
    }
}
