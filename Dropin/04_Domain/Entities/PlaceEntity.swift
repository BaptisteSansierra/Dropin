//
//  Place.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import CoreLocation

struct PlaceEntity: Identifiable {
    let id: String
    var name: String = ""
    var coordinates: CLLocationCoordinate2D = CLLocationCoordinate2D.zero
    var address: String = ""
    var systemImage: String = "tag"
    var tagIds: [String] = [String]()
    var groupId: String? = nil
    var notes: String? = nil
    var phone: String? = nil
    var url: String? = nil
    var creationDate: Date
    // following propertie are not part of the DB model
    var groupColor: String?

    init(id: String, name: String, coordinates: CLLocationCoordinate2D, address: String, systemImage: String, tagIds: [String], groupId: String? = nil, notes: String? = nil, phone: String? = nil, url: String? = nil, creationDate: Date) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = address
        self.systemImage = systemImage
        self.tagIds = tagIds
        self.groupId = groupId
        self.notes = notes
        self.phone = phone
        self.url = url
        self.creationDate = creationDate
    }
    
    init(coordinates: CLLocationCoordinate2D) {
        id = UUID().uuidString
        self.coordinates = coordinates
        creationDate = Date()
    }
}
