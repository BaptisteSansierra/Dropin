//
//  SupabaseCategoryDTO.swift
//  Dropin

import Foundation

struct SupabaseCategoryDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let color: String
    let icon: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let importedAt: Date?
    let importSrc: String?
    let spaceId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case name
        case color
        case icon
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case importedAt = "imported_at"
        case importSrc = "import_source"
        case spaceId   = "space_id"
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
        try c.encode(importedAt, forKey: .importedAt)
        try c.encode(importSrc, forKey: .importSrc)
        try c.encode(spaceId,   forKey: .spaceId)
    }

    init(from category: Category, userId: UUID) {
        self.id        = category.id
        self.userId    = userId
        self.name      = category.name
        self.color     = category.color
        self.icon      = category.icon.rawValue
        self.createdAt = category.createdAt
        self.updatedAt = category.updatedAt
        self.deletedAt = category.deletedAt
        self.importedAt = category.importedAt
        self.importSrc  = category.importSrc?.rawValue
        // Pushed entity always come from an already-persisted local fetch, which
        // always has a real spaceId. A nil here means a genuine bug, so fail loudly.
        guard let spaceId = category.spaceId else {
            preconditionFailure("Category \(category.id) has no spaceId — cannot push an entity that was never persisted")
        }
        self.spaceId = spaceId
    }

    func toDomain() -> Category {
        Category(id: id, name: name, color: color,
                    icon: Icon(rawValue: icon) ?? .sf("questionmark"),
                    createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt,
                    importedAt: importedAt, importSrc: importSrc.flatMap(ImportSource.init(rawValue:)),
                    spaceId: spaceId)
    }
}
