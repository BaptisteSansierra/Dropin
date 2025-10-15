//
//  Tag.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct TagEntity {
    let id: String
    var name: String
    var color: String
    var places: [PlaceEntity] = [PlaceEntity]()
    var creationDate: Date
    // following propertie are not part of the DB model
    /// When  databaseDeleted is true, domain objects should be ignored
    var databaseDeleted: Bool = false

    init(id: String, name: String, color: String, places: [PlaceEntity], creationDate: Date, databaseDeleted: Bool = false) {
        self.id = id
        self.name = name
        self.color = color
        self.places = places
        self.creationDate = creationDate
        self.databaseDeleted = databaseDeleted
    }
    
    init(name: String, color: String) {
        self.id = UUID().uuidString
        self.name = name
        self.color = color
        creationDate = Date()
    }
}
