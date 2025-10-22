//
//  GroupEntity.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

struct GroupEntity: Hashable {
    let id: String
    var name: String
    var places: [PlaceEntity] = [PlaceEntity]()
    var color: String
    var creationDate: Date
    // following propertie are not part of the DB model
    /// When  databaseDeleted is true, domain objects should be ignored
    var databaseDeleted: Bool = false
    
    init(id: String, name: String, places: [PlaceEntity], color: String, creationDate: Date, databaseDeleted: Bool = false) {
        self.id = id
        self.name = name
        self.places = places
        self.color = color
        self.creationDate = creationDate
        self.databaseDeleted = databaseDeleted
    }
    
    init(name: String, color: String) {
        self.id = UUID().uuidString
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
