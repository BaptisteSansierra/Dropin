//
//  Category.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct Category: Hashable, Sendable {
    let id: UUID
    let name: String
    let icon: Icon
    let color: String
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var importedAt: Date?
    var importSrc: ImportSource?
    // Not nil spaceId is Storage partition: nil means "not yet persisted"
    // The repository resolves it on insert; callers constructing a domain object never need to know about spaces.
    var spaceId: UUID?
    // Note: places are not stored here to avoid bidirectional relationships
    // Place owns the relationship

    // Used by mappers
    init(id: UUID,
         name: String,
         color: String,
         icon: Icon,
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date?,
         importedAt: Date? = nil,
         importSrc: ImportSource? = nil,
         spaceId: UUID? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.importedAt = importedAt
        self.importSrc = importSrc
        self.spaceId = spaceId
    }

    init(name: String, color: String, icon: Icon, importedAt: Date? = nil, importSrc: ImportSource? = nil) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        let now = Date()
        createdAt = now
        updatedAt = now
        deletedAt = nil
        self.importedAt = importedAt
        self.importSrc = importSrc
        self.spaceId = nil
    }
    
    func deleted(deletedAt: Date) -> Category {
        var copy = self
        copy.deletedAt = deletedAt
        return copy
    }

    func undeleted() -> Category {
        var copy = self
        copy.deletedAt = nil
        return copy
    }
    
    func updated() -> Category {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }

    /// Used by importers to stamp provenance on an already-constructed Category
    /// (e.g. one just decoded from a file).
    func withImportProvenance(importedAt: Date, importSrc: ImportSource) -> Category {
        var copy = self
        copy.importedAt = importedAt
        copy.importSrc = importSrc
        return copy
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Category {
    var isActive: Bool { deletedAt == nil }
}
