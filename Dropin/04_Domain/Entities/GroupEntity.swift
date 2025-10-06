//
//  GroupEntity.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct GroupEntity: Identifiable {
    let id: String
    var name: String
    var places: [PlaceEntity] = [PlaceEntity]()
    var color: String
    var creationDate: Date
    
    init(id: String, name: String, places: [PlaceEntity], color: String, creationDate: Date) {
        self.id = id
        self.name = name
        self.places = places
        self.color = color
        self.creationDate = creationDate
    }
    
    init(name: String, color: String) {
        self.id = UUID().uuidString
        self.name = name
        self.color = color
        creationDate = Date()
    }
}
