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
    var identifier: String
    var name: String
    var latitude: Double
    var longitude: Double
    var address: String
    var systemImage: String
    @Relationship(deleteRule: .nullify, inverse: \SDTag.places) var tags: [SDTag]
    @Relationship(deleteRule: .nullify, inverse: \SDGroup.places) var group: SDGroup?
    var notes: String?
    var phone: String?
    var url: String?
    @Attribute(.externalStorage) var image: Data?
    var creationDate: Date
    
    init(identifier: String,
         name: String,
         latitude: Double,
         longitude: Double,
         address: String,
         systemImage: String? = nil,
         tags: [SDTag] = [],
         group: SDGroup? = nil,
         notes: String? = nil,
         phone: String? = nil,
         url: String? = nil) {
        self.identifier = identifier
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
}

#if DEBUG

extension SDPlace {  // Mock extension
    
    static func mockPlaces() -> [SDPlace] {
        let l1 = SDPlace(identifier: UUID().uuidString,
                         name: "La Chitarra",
                        latitude: 41.40622777528736,
                        longitude: 2.1595467749244204,
                        address: "Carrer de Joan Blanques, 56, \nGràcia, \n08024 Barcelona",
                        systemImage: "fork.knife.circle",
                        tags: [],
                        group: nil)

        let l2 = SDPlace(identifier: UUID().uuidString,
                         name: "Les Tres a la Cuina",
                                latitude: 41.40522138362398,
                                longitude: 2.1598304185317847,
                                // Apple
                                //latitude: 41.405341,
                                //longitude: 2.159652,
                                address: "Carrer de Sant Lluís, 35, Gràcia, 08012 Barcelona",
                                systemImage: "fork.knife.circle",
                                tags: [],
                                group: nil,
                                notes: "Don't forget your tupper",
                                phone: "931054947",
                                url: "http://lestresalacuina.com")
        
        let l3 = SDPlace(identifier: UUID().uuidString,
                         name: "Chiringuito Karamba",
                                latitude: 41.44511384541266,
                                longitude: 2.2495646936392317,
                                address: "Carrer d'Eduard Maristany, 21, 08912 Badalona, Barcelona",
                                systemImage: "fork.knife.circle",
                                tags: [],
                                group: nil)

        let l4 = SDPlace(identifier: UUID().uuidString,
                         name: "Continental Bar",
                                latitude: 41.40626764285292,
                                longitude: 2.156492157860694,
                                address: "Carrer de la Providència, 30, /nGràcia, /n08024 Barcelona",
                                systemImage: "wineglass",
                                tags: [],
                                group: nil)

        let l5 = SDPlace(identifier: UUID().uuidString,
                         name: "Bagdad café",
                                latitude: 33.321589923265904,
                                longitude: 44.416811639303546,
                                address: "Rasafi Street, Baghdad, Baghdad Governorate, Irak",
                                systemImage: "pianokeys",
                                tags: [],
                                group: nil)

        let l6 = SDPlace(identifier: UUID().uuidString,
                         name: "El Col·leccionista",
                                latitude: 41.40602900686343,
                                longitude: 2.160639939265184,
                                address: "Carrer del Torrent de les Flors, 46, Gràcia, 08024 Barcelona",
                                systemImage: "figure.socialdance",
                                tags: [],
                                group: nil)

        let l7 = SDPlace(identifier: UUID().uuidString,
                         name: "Molsa Biosí",
                                latitude: 41.403067387301924,
                                longitude: 2.158858952034207,
                                address: "Carrer de Ramón y Cajal, 42, Gràcia, 08012 Barcelona",
                                systemImage: "carrot",
                                tags: [],
                                group: nil)

        let l8 = SDPlace(identifier: UUID().uuidString,
                         name: "Sincronia Yoga",
                                latitude: 41.40068001375675,
                                longitude: 2.155838283307449,
                                address: "Carrer de Pere Serafí, 7, Gràcia, 08012 Barcelona",
                                systemImage: "swirl.circle.righthalf.filled.inverse",
                                tags: [],
                                group: nil)

        let l9 = SDPlace(identifier: UUID().uuidString,
                         name: "Be Laundry Joanic",
                                latitude: 41.399426209480154,
                                longitude: 2.154584065083631,
                                address: "Carrer de l'escorial, 20\n08024 Barcelona Barcelona\nSpain",
                                systemImage: "basket",
                                tags: [],
                                group: nil)

        return [l1, l2, l3, l4, l5, l6, l7, l8, l9]
    }
}
#endif
