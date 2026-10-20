//
//  Tag.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct Tag: Hashable, Sendable {
    let id: UUID
    let name: String
    let color: String
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var importedAt: Date?
    var importSrc: ImportSource?
    // Note: places are not stored here to avoid bidirectional relationships
    // Place owns the relationship

    // Used by mappers
    init(id: UUID,
         name: String,
         color: String,
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date?,
         importedAt: Date? = nil,
         importSrc: ImportSource? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.importedAt = importedAt
        self.importSrc = importSrc
    }

    init(name: String, color: String, importedAt: Date? = nil, importSrc: ImportSource? = nil) {
        self.id = UUID()
        self.name = name
        self.color = color
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
        self.importedAt = importedAt
        self.importSrc = importSrc
    }
    
    func deleted(deletedAt: Date) -> Tag {
        var copy = self
        copy.deletedAt = deletedAt
        return copy
    }

    func undeleted() -> Tag {
        var copy = self
        copy.deletedAt = nil
        return copy
    }
    
    func updated() -> Tag {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }

    /// Used by importers to stamp provenance on an already-constructed Tag
    /// (e.g. one just decoded from a file).
    func withImportProvenance(importedAt: Date, importSrc: ImportSource) -> Tag {
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

extension Tag {
    var isActive: Bool { deletedAt == nil }
}
