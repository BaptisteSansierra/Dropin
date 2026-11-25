//
//  DropinCategoryDTO.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/10/26.
//

import Foundation

/// .dropin wire format for a category.
/// `id` is a file-local reference (used by DropinPlaceDTO.categoryId), never persisted as is.
struct DropinCategoryDTO: Codable, Sendable {

    let id: UUID
    var name: String
    var icon: Icon
    var color: String

    init(_ category: Category) {
        self.id = category.id
        self.name = category.name
        self.icon = category.icon
        self.color = category.color
    }

    /// Creates a new domain category: fresh id, every date set to `importDate`
    func toDomain(importDate: Date) -> Category {
        Category(id: UUID(),
                 name: name,
                 color: color,
                 icon: icon,
                 createdAt: importDate,
                 updatedAt: importDate,
                 deletedAt: nil,
                 importedAt: importDate,
                 importSrc: .dropin)
    }
}
