//
//  SupabaseGroupDTO.swift
//  Dropin

import Foundation

struct SupabaseGroupDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let color: String
    let icon: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case name
        case color
        case icon
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    /// Explicit encode so `deleted_at: null` is sent over the wire (Postgrest upsert would
    /// otherwise preserve the existing value if the key is missing). See SupabasePlaceDTO.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(userId,    forKey: .userId)
        try c.encode(name,      forKey: .name)
        try c.encode(color,     forKey: .color)
        try c.encode(icon,      forKey: .icon)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(deletedAt, forKey: .deletedAt)
    }

    init(from group: GroupEntity, userId: UUID) {
        self.id        = group.id
        self.userId    = userId
        self.name      = group.name
        self.color     = group.color
        self.icon      = group.icon.rawValue
        self.createdAt = group.createdAt
        self.updatedAt = group.updatedAt
        self.deletedAt = group.deletedAt
    }

    func toDomain() -> GroupEntity {
        GroupEntity(id: id, name: name, color: color,
                    icon: Icon(rawValue: icon) ?? .sf("questionmark"),
                    createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt)
    }
}
