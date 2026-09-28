//
//  CategoryMapper.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

public enum CategoryMapper {
    
    static func toDomain(_ sdCategory: CategoryRecord) -> Category {
        let category = Category(id: sdCategory.identifier,
                                name: sdCategory.name,
                                color: sdCategory.color,
                                icon: sdCategory.icon,
                                createdAt: sdCategory.createdAt,
                                updatedAt: sdCategory.updatedAt,
                                deletedAt: sdCategory.deletedAt)
        return category
    }
    
    static func toData(_ category: Category) -> CategoryRecord {
        let sd = CategoryRecord(identifier: category.id,
                         name: category.name,
                         color: category.color,
                         icon: category.icon)
        // CategoryRecord.init hardcodes fresh dates; preserve domain timestamps so
        // server-originated rows (incl. soft-deletes) survive a pull.
        sd.createdAt = category.createdAt
        sd.updatedAt = category.updatedAt
        sd.deletedAt = category.deletedAt
        return sd
    }
}
