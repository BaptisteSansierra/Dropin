//
//  DropinTagDTO.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/10/26.
//

import Foundation

/// .dropin wire format for a tag.
/// `id` is a file-local reference (used by DropinPlaceDTO.tagIds), never persisted as is.
struct DropinTagDTO: Codable, Sendable {

    let id: UUID
    var name: String
    var color: String

    init(_ tag: Tag) {
        self.id = tag.id
        self.name = tag.name
        self.color = tag.color
    }

    /// Creates a new domain tag: fresh id, every date set to `importDate`
    func toDomain(importDate: Date) -> Tag {
        Tag(id: UUID(),
            name: name,
            color: color,
            createdAt: importDate,
            updatedAt: importDate,
            deletedAt: nil,
            importedAt: importDate,
            importSrc: .dropin)
    }
}
