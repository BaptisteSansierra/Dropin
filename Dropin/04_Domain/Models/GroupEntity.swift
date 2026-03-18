//
//  GroupEntity.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct GroupEntity: Hashable {
    let id: UUID
    var name: String
    var icon: Icon
    var places: [PlaceEntity] = [PlaceEntity]()
    var color: String
    var creationDate: Date
    var deletionDate: Date? = nil
    
    init(id: UUID, name: String, color: String, icon: Icon, places: [PlaceEntity], creationDate: Date, deletionDate: Date? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.places = places
        self.creationDate = creationDate
        self.deletionDate = deletionDate
    }
    
    init(name: String, color: String, icon: Icon) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        creationDate = Date()
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
