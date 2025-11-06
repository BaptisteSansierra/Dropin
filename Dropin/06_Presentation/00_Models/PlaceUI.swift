//
//  PlaceUI.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/25.
//

import SwiftUI
import CoreLocation

@MainActor
@Observable class PlaceUI: Identifiable {
    let id: String
    var name: String = ""
    var coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D.zero
    var address: String = ""
    var icon: Icon? = nil
    var tags: [TagUI] = [TagUI]()
    var group: GroupUI? = nil
    var notes: String? = nil
    var phone: String? = nil
    var url: String? = nil
    var creationDate: Date
    // following propertie are not part of the DB model
    /// When  databaseDeleted is true, UI objects should be ignored
    var databaseDeleted: Bool = false

    var groupColor: Color {
        guard let group = self.group else { return .dropinPrimary }
        return group.color
    }

    init(id: String,
         name: String,
         coordinates: CLLocationCoordinate2D,
         address: String,
         tags: [TagUI],
         group: GroupUI? = nil,
         icon: Icon? = nil,
         notes: String? = nil,
         phone: String? = nil,
         url: String? = nil,
         creationDate: Date,
         databaseDeleted: Bool) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = address
        self.tags = tags
        self.group = group
        self.icon = icon
        self.notes = notes
        self.phone = phone
        self.url = url
        self.creationDate = creationDate
        self.databaseDeleted = databaseDeleted
    }

    init(coordinates: CLLocationCoordinate2D) {
        id = UUID().uuidString
        self.coordinates = coordinates
        creationDate = Date()
    }
    
    func copy() -> PlaceUI {
        return PlaceUI(id: id,
                       name: name,
                       coordinates: coordinates,
                       address: address,
                       tags: tags,
                       group: group,
                       icon: icon,
                       notes: notes,
                       phone: phone,
                       url: url,
                       creationDate: creationDate,
                       databaseDeleted: databaseDeleted)
    }
}
