//
//  PlaceEntity+Extension.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
import CoreLocation
@testable import Dropin

extension PlaceEntity {  // Mock extension
    static func mockPlaces() -> [PlaceEntity] {
        let l1 = PlaceEntity(id: UUID().uuidString,
                             name: "La Chitarra",
                             coordinates: CLLocationCoordinate2D(latitude: 41.40622777528736, longitude: 2.1595467749244204),
                             address: "Carrer de Joan Blanques, 56, \nGràcia, \n08024 Barcelona",
                             systemImage: "fork.knife.circle",
                             tags: [],
                             group: nil,
                             creationDate: Date()
                             )

        let l2 = PlaceEntity(id: UUID().uuidString,
                             name: "Les Tres a la Cuina",
                             coordinates: CLLocationCoordinate2D(latitude: 41.40522138362398, longitude: 2.1598304185317847),
                             // Apple
                             //coordinates: CLLocationCoordinate2D(latitude: 41.405341,
                             //longitude: 2.159652,
                             address: "Carrer de Sant Lluís, 35, Gràcia, 08012 Barcelona",
                             systemImage: "fork.knife.circle",
                             tags: [],
                             group: nil,
                             notes: "Don't forget your tupper",
                             phone: "931054947",
                             url: "http://lestresalacuina.com",
                             creationDate: Date(),
                             )

        
        let l3 = PlaceEntity(id: UUID().uuidString,
                             name: "Chiringuito Karamba",
                             coordinates: CLLocationCoordinate2D(latitude: 41.44511384541266, longitude: 2.2495646936392317),
                             address: "Carrer d'Eduard Maristany, 21, 08912 Badalona, Barcelona",
                             systemImage: "fork.knife.circle",
                             tags: [],
                             group: nil,
                             creationDate: Date()
                             )

        let l4 = PlaceEntity(id: UUID().uuidString,
                             name: "Continental Bar",
                             coordinates: CLLocationCoordinate2D(latitude: 41.40626764285292, longitude: 2.156492157860694),
                             address: "Carrer de la Providència, 30, /nGràcia, /n08024 Barcelona",
                             systemImage: "wineglass",
                             tags: [],
                             group: nil,
                             creationDate: Date()
                             )

        let l5 = PlaceEntity(id: UUID().uuidString,
                             name: "Bagdad café",
                             coordinates: CLLocationCoordinate2D(latitude: 33.321589923265904, longitude: 44.416811639303546),
                             address: "Rasafi Street, Baghdad, Baghdad Governorate, Irak",
                             systemImage: "pianokeys",
                             tags: [],
                             group: nil,
                             creationDate: Date()
                             )


        let l6 = PlaceEntity(id: UUID().uuidString,
                             name: "El Col·leccionista",
                             coordinates: CLLocationCoordinate2D(latitude: 41.40602900686343, longitude: 2.160639939265184),
                             address: "Carrer del Torrent de les Flors, 46, Gràcia, 08024 Barcelona",
                             systemImage: "figure.socialdance",
                             tags: [],
                             group: nil,
                             creationDate: Date()
                             )

        let l7 = PlaceEntity(id: UUID().uuidString,
                             name: "Molsa Biosí",
                             coordinates: CLLocationCoordinate2D(latitude: 41.403067387301924, longitude: 2.158858952034207),
                             address: "Carrer de Ramón y Cajal, 42, Gràcia, 08012 Barcelona",
                             systemImage: "carrot",
                             tags: [],
                             group: nil,
                             creationDate: Date()
                            )


        let l8 = PlaceEntity(id: UUID().uuidString,
                             name: "Sincronia Yoga",
                             coordinates: CLLocationCoordinate2D(latitude: 41.40068001375675, longitude: 2.155838283307449),
                             address: "Carrer de Pere Serafí, 7, Gràcia, 08012 Barcelona",
                             systemImage: "swirl.circle.righthalf.filled.inverse",
                             tags: [],
                             group: nil,
                             creationDate: Date()
                             )


        let l9 = PlaceEntity(id: UUID().uuidString,
                             name: "Be Laundry Joanic",
                             coordinates: CLLocationCoordinate2D(latitude: 41.399426209480154, longitude: 2.154584065083631),
                             address: "Carrer de l'escorial, 20\n08024 Barcelona Barcelona\nSpain",
                             systemImage: "basket",
                             tags: [],
                             group: nil,
                             creationDate: Date()
                             )
        return [l1, l2, l3, l4, l5, l6, l7, l8, l9]
    }
}
