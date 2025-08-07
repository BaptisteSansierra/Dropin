//
//  SDPlace.swift
//  Dropin
//
//  Created by baptiste sansierra on 22/7/25.
//

import Foundation
import SwiftData

@Model
final class SDPlace {
    var name: String
    var latitude: Double
    var longitude: Double
    var address: String
    var systemImage: String
    @Relationship(deleteRule: .nullify, inverse: \SDTag.locations) var tags: [SDTag]
    @Relationship(deleteRule: .nullify, inverse: \SDGroup.locations) var group: SDGroup?
    var notes: String?
    var phone: String?
    var url: String?
    @Attribute(.externalStorage) var image: Data?
    var creationDate: Date

    init(name: String,
         latitude: Double,
         longitude: Double,
         address: String,
         tags: [SDTag] = [],
         group: SDGroup? = nil,
         notes: String? = nil) {
        self.creationDate = Date()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.systemImage = "tag"
        self.address = address
        self.tags = tags
        self.group = group
        self.notes = notes
        self.systemImage = systemImage
    }
    
    func sortedTags() -> [SDTag] {
        return tags.sorted { t1, t2 in
            let comparisonResult = t1.name.compare(t2.name)
            if comparisonResult == .orderedSame {
                return t1.creationDate.compare(t2.creationDate) == .orderedAscending
            }
            return comparisonResult == .orderedAscending
        }
    }
    
    #if DEBUG
    
    static let l1 = SDPlace(name: "La Chitarra",
                            latitude: 41.40622777528736,
                            longitude: 2.1595467749244204,
                            address: "Carrer de Joan Blanques, 56, \nGràcia, \n08024 Barcelona",
                            tags: [SDTag.t9, SDTag.t11],
                            group: SDGroup.g1)

    static let l2 = SDPlace(name: "Les Tres a la Cuina",
                            latitude: 41.40522138362398,
                            longitude: 2.1598304185317847,
                            // Apple
                            //latitude: 41.405341,
                            //longitude: 2.159652,
                            address: "Carrer de Sant Lluís, 35, Gràcia, 08012 Barcelona",
                            tags: [SDTag.t9, SDTag.t10],
                            group: SDGroup.g1)
    
    static let l3 = SDPlace(name: "Chiringuito Karamba",
                            latitude: 41.44511384541266,
                            longitude: 2.2495646936392317,
                            address: "Carrer d'Eduard Maristany, 21, 08912 Badalona, Barcelona",
                            tags: [SDTag.t7, SDTag.t8],
                            group: SDGroup.g5)

    static let l4 = SDPlace(name: "Chez oim",
                            latitude: 41.403383362193004,
                            longitude: 2.1601241159740505,
                            address: "Carrer del Torrent d'En Vidalet, 7, Gràcia, 08012 Barcelona",
                            tags: [SDTag.t1],
                            group: nil)

    static let l5 = SDPlace(name: "Bagdad café",
                            latitude: 33.321589923265904,
                            longitude: 44.416811639303546,
                            address: "Rasafi Street, Baghdad, Baghdad Governorate, Irak",
                            tags: [SDTag.t2],
                            group: SDGroup.g6)

    
//    static let locEx1 = SDPlace(name: "Barcelona",
//                                   latitude: 41.38879,
//                                   longitude: 2.15899,
//                                   address: "Barcelona, SPAIN",
//                                   tags: [SDTag.t1, SDTag.t2, SDTag.t3, SDTag.t4, SDTag.t5, SDTag.t6, SDTag.t7, SDTag.t8])
//    static let locEx2 = SDPlace(name: "Badalona",
//                                   latitude: 41.45004,
//                                   longitude: 2.24741,
//                                   address: "Badalona, SPAIN",
//                                   tags: [SDTag.t1, SDTag.t3, SDTag.t5, SDTag.t7])
    #endif
}
