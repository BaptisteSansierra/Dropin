//
//  GroupEntity.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct GroupEntity: Hashable {
    let id: UUID
    let name: String
    let icon: Icon
    var places: [PlaceEntity] = [PlaceEntity]()
    let color: String
    let createdAt: Date
    let deletedAt: Date?
    
    init(id: UUID, name: String, color: String, icon: Icon, places: [PlaceEntity], createdAt: Date, deletedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.places = places
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
    
    init(name: String, color: String, icon: Icon) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        createdAt = Date()
        deletedAt = nil
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
