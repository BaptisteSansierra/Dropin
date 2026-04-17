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
    var identifier: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var address: String
    var address2: String
    @Relationship(deleteRule: .nullify, inverse: \SDTag.places) var tags: [SDTag]
    @Relationship(deleteRule: .nullify, inverse: \SDGroup.places) var group: SDGroup?
    var icon: Icon? = nil
    var createdAt: Date
    // Metadata
    var rating: Float? = nil
    var phone: [String]
    var email: [String]
    var url: [String]
    var notes: String?
    @Attribute(.externalStorage) var images: [Data]
    var deletedAt: Date?

    init(identifier: UUID,
         name: String,
         latitude: Double,
         longitude: Double,
         address: String,
         address2: String = "",
         tags: [SDTag] = [],
         group: SDGroup? = nil,
         icon: Icon? = nil,
         rating: Float? = nil,
         phone: [String] = [],
         email: [String] = [],
         url: [String] = [],
         notes: String? = nil,
         images: [Data] = []) {
        self.identifier = identifier
        self.createdAt = Date()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.address2 = address2
        self.tags = tags
        self.group = group
        self.icon = icon
        self.rating = rating
        self.phone = phone
        self.email = email
        self.url = url
        self.notes = notes
        self.images = images
        self.deletedAt = nil
    }
}

#if DEBUG

import ContactFieldKit

extension SDPlace {  // Mock extension
    
    static func mockPlaces() -> [SDPlace] {
        let l1 = SDPlace(identifier: UUID(),
                         name: "La Chitarra",
                         latitude: 41.40622777528736,
                         longitude: 2.1595467749244204,
                         address: "Carrer de Joan Blanques, 56, \nGràcia, \n08024 Barcelona",
                         tags: [],
                         group: nil,
                         icon: .sf("carrot.fill"))

        let l2 = SDPlace(identifier: UUID(),
                         name: "Les Tres a la Cuina",
                         latitude: 41.40522138362398,
                         longitude: 2.1598304185317847,
                         // Apple
                         //latitude: 41.405341,
                         //longitude: 2.159652,
                         address: "Carrer de Sant Lluís, 35, Gràcia, 08012 Barcelona",
                         tags: [],
                         group: nil,
                         phone: [ContactItem(value: "931054947", label: ContactLabel(kind: .phone, label: .mobile)).rawValue,
                                 ContactItem(value: "633029920", label: ContactLabel(kind: .phone, label: .home)).rawValue],
                         email: [ContactItem(value: "tres.a.la@cuina.es", label: ContactLabel(kind: .email, label: .work)).rawValue],
                         url: [ContactItem(value: "http://lestresalacuina.com", label: ContactLabel(kind: .url, label: .url)).rawValue],
                         notes: "Don't forget your tupper")
        
        let l3 = SDPlace(identifier: UUID(),
                         name: "Chiringuito Karamba",
                        latitude: 41.44511384541266,
                        longitude: 2.2495646936392317,
                        address: "Carrer d'Eduard Maristany, 21, 08912 Badalona, Barcelona",
                        tags: [],
                        group: nil)

        let l4 = SDPlace(identifier: UUID(),
                         name: "Continental Bar",
                         latitude: 41.40626764285292,
                         longitude: 2.156492157860694,
                         address: "Carrer de la Providència, 30, /nGràcia, /n08024 Barcelona",
                         tags: [],
                         group: nil)

        let l5 = SDPlace(identifier: UUID(),
                         name: "Bagdad café",
                         latitude: 33.321589923265904,
                         longitude: 44.416811639303546,
                         address: "Rasafi Street,\nBaghdad,\nBaghdad Governorate, Irak",
                         tags: [],
                         group: nil,
                         icon: .sf("pianokeys"))

        let l6 = SDPlace(identifier: UUID(),
                         name: "El Col·leccionista",
                         latitude: 41.40602900686343,
                         longitude: 2.160639939265184,
                         address: "Carrer del Torrent de les Flors, 46, Gràcia, 08024 Barcelona",
                         tags: [],
                         group: nil,
                         icon: .sf("figure.socialdance"))

        let l7 = SDPlace(identifier: UUID(),
                         name: "Molsa Biosí",
                         latitude: 41.403067387301924,
                         longitude: 2.158858952034207,
                         address: "Carrer de Ramón y Cajal, 42, Gràcia, 08012 Barcelona",
                         tags: [],
                         group: nil,
                         icon: .sf("carrot"))

        let l8 = SDPlace(identifier: UUID(),
                         name: "Sincronia Yoga",
                         latitude: 41.40068001375675,
                         longitude: 2.155838283307449,
                         address: "Carrer de Pere Serafí, 7, Gràcia, 08012 Barcelona",
                         tags: [],
                         group: nil,
                         icon: .sf("swirl.circle.righthalf.filled.inverse"))

        let l9 = SDPlace(identifier: UUID(),
                         name: "Be Laundry Joanic",
                         latitude: 41.399426209480154,
                         longitude: 2.154584065083631,
                         address: "Carrer de l'escorial, 20\n08024 Barcelona Barcelona\nSpain",
                         tags: [],
                         group: nil,
                         icon: .sf("basket"))

        return [l1, l2, l3, l4, l5, l6, l7, l8, l9]
    }
}
#endif
