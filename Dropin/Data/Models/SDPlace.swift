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
         systemImage: String? = nil,
         tags: [SDTag] = [],
         group: SDGroup? = nil,
         notes: String? = nil,
         phone: String? = nil,
         url: String? = nil) {
        self.creationDate = Date()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.systemImage = systemImage ?? "tag"
        self.address = address
        self.tags = tags
        self.group = group
        self.notes = notes
        self.phone = phone
        self.url = url
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
                            systemImage: "fork.knife.circle",
                            tags: [SDTag.t9, SDTag.t11, SDTag.t14],
                            group: SDGroup.g1)

    static let l2 = SDPlace(name: "Les Tres a la Cuina",
                            latitude: 41.40522138362398,
                            longitude: 2.1598304185317847,
                            // Apple
                            //latitude: 41.405341,
                            //longitude: 2.159652,
                            address: "Carrer de Sant Lluís, 35, Gràcia, 08012 Barcelona",
                            systemImage: "fork.knife.circle",
                            tags: [SDTag.t9, SDTag.t10, SDTag.t14],
                            group: SDGroup.g1,
                            notes: "Don't forget your tupper",
                            phone: "931054947",
                            url: "http://lestresalacuina.com")
    
    static let l3 = SDPlace(name: "Chiringuito Karamba",
                            latitude: 41.44511384541266,
                            longitude: 2.2495646936392317,
                            address: "Carrer d'Eduard Maristany, 21, 08912 Badalona, Barcelona",
                            systemImage: "fork.knife.circle",
                            tags: [SDTag.t7, SDTag.t8],
                            group: SDGroup.g5)

    static let l4 = SDPlace(name: "Continental Bar",
                            latitude: 41.40626764285292,
                            longitude: 2.156492157860694,
                            address: "Carrer de la Providència, 30, /nGràcia, /n08024 Barcelona",
                            systemImage: "wineglass",
                            tags: [SDTag.t2],
                            group: SDGroup.g6)

    static let l5 = SDPlace(name: "Bagdad café",
                            latitude: 33.321589923265904,
                            longitude: 44.416811639303546,
                            address: "Rasafi Street, Baghdad, Baghdad Governorate, Irak",
                            systemImage: "pianokeys",
                            tags: [SDTag.t2],
                            group: SDGroup.g6)

    static let l6 = SDPlace(name: "El Col·leccionista",
                            latitude: 41.40602900686343,
                            longitude: 2.160639939265184,
                            address: "Carrer del Torrent de les Flors, 46, Gràcia, 08024 Barcelona",
                            systemImage: "figure.socialdance",
                            tags: [SDTag.t12, SDTag.t13],
                            group: SDGroup.g6)

    static let l7 = SDPlace(name: "Molsa Biosí",
                            latitude: 41.403067387301924,
                            longitude: 2.158858952034207,
                            address: "Carrer de Ramón y Cajal, 42, Gràcia, 08012 Barcelona",
                            systemImage: "carrot",
                            tags: [SDTag.t10, SDTag.t13],
                            group: SDGroup.g8)

    static let l8 = SDPlace(name: "Sincronia Yoga",
                            latitude: 41.40068001375675,
                            longitude: 2.155838283307449,
                            address: "Carrer de Pere Serafí, 7, Gràcia, 08012 Barcelona",
                            systemImage: "swirl.circle.righthalf.filled.inverse",
                            tags: [SDTag.t10],
                            group: SDGroup.g9)

    static let all = [l1, l2, l3, l4, l5, l6, l7, l8]
    
    #endif
}
