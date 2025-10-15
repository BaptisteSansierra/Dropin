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
    var systemImage: String = "tag"
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

    init(id: String, name: String, coordinates: CLLocationCoordinate2D, address: String, systemImage: String, tags: [TagUI], group: GroupUI? = nil, notes: String? = nil, phone: String? = nil, url: String? = nil, creationDate: Date, databaseDeleted: Bool) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = address
        self.systemImage = systemImage
        self.tags = tags
        self.group = group
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
    
//    static func == (lhs: PlaceUI, rhs: PlaceUI) -> Bool {
//        return lhs.id == rhs.id
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
}
