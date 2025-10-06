//
//  Tag.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct TagEntity: Identifiable {
    let id: String
    var name: String
    var color: String
    var places: [PlaceEntity] = [PlaceEntity]()
    var creationDate: Date

    init(id: String, name: String, color: String, places: [PlaceEntity], creationDate: Date) {
        self.id = id
        self.name = name
        self.color = color
        self.places = places
        self.creationDate = creationDate
    }
    
    init(name: String, color: String) {
        self.id = UUID().uuidString
        self.name = name
        self.color = color
        creationDate = Date()
    }
}
