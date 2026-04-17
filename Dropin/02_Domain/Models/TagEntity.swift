//
//  Tag.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct TagEntity: Hashable {
    let id: UUID
    let name: String
    let color: String
    var places: [PlaceEntity] = [PlaceEntity]()
    let createdAt: Date
    let deletedAt: Date?

    init(id: UUID, name: String, color: String, places: [PlaceEntity], createdAt: Date, deletedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.places = places
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
    
    init(name: String, color: String) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
        self.deletedAt = nil
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
