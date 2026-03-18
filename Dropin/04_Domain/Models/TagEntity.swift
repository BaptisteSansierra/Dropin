//
//  Tag.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct TagEntity: Hashable {
    let id: UUID
    var name: String
    var color: String
    var places: [PlaceEntity] = [PlaceEntity]()
    var creationDate: Date
    var deletionDate: Date? = nil

    init(id: UUID, name: String, color: String, places: [PlaceEntity], creationDate: Date, deletionDate: Date? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.places = places
        self.creationDate = creationDate
        self.deletionDate = deletionDate
    }
    
    init(name: String, color: String) {
        self.id = UUID()
        self.name = name
        self.color = color
        creationDate = Date()
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
