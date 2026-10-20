//
//  CategoryUIModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI

@MainActor
@Observable class CategoryUIModel: Identifiable {

    let id: UUID
    var name: String
    var icon: Icon
    var color: Color
    var places: [PlaceUIModel]
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    let importedAt: Date?
    let importSrc: ImportSource?
    let spaceId: UUID?

    // used to get place count when places are not populated
    var placeCount: Int = -1

    var isActive: Bool {
        deletedAt == nil
    }

    init(id: UUID,
         name: String,
         color: String,
         icon: Icon,
         places: [PlaceUIModel],
         createdAt: Date,
         updatedAt: Date,
         deletedAt: Date?,
         importedAt: Date? = nil,
         importSrc: ImportSource? = nil,
         spaceId: UUID? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = Color(rgba: color)
        self.places = places
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.importedAt = importedAt
        self.importSrc = importSrc
        self.spaceId = spaceId
    }

    #if DEBUG
    init(color: String) {
        self.id = UUID()
        self.name = "RANDOM"
        self.icon = Icon(rawValue: "sf:infinity.circle")!
        self.color = Color(rgba: color)
        self.places = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.deletedAt = nil
        self.importedAt = nil
        self.importSrc = nil
        self.spaceId = nil
    }
    #endif
}
