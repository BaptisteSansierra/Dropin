//
//  CategoryMapper+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import Foundation

@MainActor
extension CategoryMapper {

    static func toUI(_ category: Category, placeCount: Int) -> CategoryUIModel {
        let groupUI = toUI(category)
        groupUI.placeCount = placeCount
        return groupUI
    }

    static func toUI(_ category: Category) -> CategoryUIModel {
        let groupUI = CategoryUIModel(id: category.id,
                              name: category.name,
                              color: category.color,
                              icon: category.icon,
                              places: [],
                              createdAt: category.createdAt,
                              updatedAt: category.updatedAt,
                              deletedAt: category.deletedAt)
        return groupUI
    }
    
    static func toDomain(_ groupUI: CategoryUIModel) -> Category {
        let category = Category(id: groupUI.id,
                                name: groupUI.name,
                                color: groupUI.color.hex,
                                icon: groupUI.icon,
                                createdAt: groupUI.createdAt,
                                updatedAt: groupUI.updatedAt,
                                deletedAt: groupUI.deletedAt)
        return category
    }
}
