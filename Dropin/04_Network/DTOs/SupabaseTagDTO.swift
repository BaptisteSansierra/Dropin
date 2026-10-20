//
//  SupabaseTagDTO.swift
//  Dropin

import Foundation

struct SupabaseTagDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let color: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let importedAt: Date?
    let importSrc: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case name
        case color
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case importedAt = "imported_at"
        case importSrc = "import_source"
    }

    /// Explicit encode so `deleted_at: null` is sent over the wire. See SupabasePlaceDTO.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(userId,    forKey: .userId)
        try c.encode(name,      forKey: .name)
        try c.encode(color,     forKey: .color)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(deletedAt, forKey: .deletedAt)
        try c.encode(importedAt, forKey: .importedAt)
        try c.encode(importSrc, forKey: .importSrc)
    }

    init(from tag: Tag, userId: UUID) {
        self.id        = tag.id
        self.userId    = userId
        self.name      = tag.name
        self.color     = tag.color
        self.createdAt = tag.createdAt
        self.updatedAt = tag.updatedAt
        self.deletedAt = tag.deletedAt
        self.importedAt = tag.importedAt
        self.importSrc  = tag.importSrc?.rawValue
    }

    func toDomain() -> Tag {
        Tag(id: id, name: name, color: color,
                  createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt,
                  importedAt: importedAt, importSrc: importSrc.flatMap(ImportSource.init(rawValue:)))
    }
}
