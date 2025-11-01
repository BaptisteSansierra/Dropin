//
//  GroupUI.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI

@MainActor
@Observable class GroupUI: Identifiable {
    let id: String
    var name: String
    var sfSymbol: String
    var color: Color
    var places: [PlaceUI] = [PlaceUI]()
    var creationDate: Date
    // following propertie are not part of the DB model
    /// When  databaseDeleted is true, UI objects should be ignored
    var databaseDeleted: Bool = false

    init(id: String, name: String, color: String, sfSymbol: String, places: [PlaceUI], creationDate: Date, databaseDeleted: Bool) {
        self.id = id
        self.name = name
        self.sfSymbol = sfSymbol
        self.color = Color(rgba: color)
        self.places = places
        self.creationDate = creationDate
        self.databaseDeleted = databaseDeleted
    }
    
//    init(name: String, color: String) {
//        self.id = UUID().uuidString
//        self.name = name
//        self.color = color
//        creationDate = Date()
//    }
}
