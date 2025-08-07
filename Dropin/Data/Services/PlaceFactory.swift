//
//  PlaceFactory.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/8/25.
//

import SwiftData
import CoreLocation
import SwiftData

@Observable class PlaceFactory {
        
    enum CreationMode {
        case coords
        case undefined
    }
    
    var place: SDPlace

    private var preparing: Bool = false
    private var creationMode: CreationMode = .undefined
    
    init() {
        place = SDPlace(name: "", latitude: 0, longitude: 0, address: "")
    }

    func prepareFromCoords(coords: CLLocationCoordinate2D) {
        preparing = true
        creationMode = .coords
        place.latitude = coords.latitude
        place.longitude = coords.longitude
    }

    func save(modelContext: ModelContext) {
        modelContext.insert(place)
        reset()
    }

    func reset() {
        place = SDPlace(name: "", latitude: 0, longitude: 0, address: "")
        preparing = false
        creationMode = .undefined
    }
    
    
    #if DEBUG
    static var preview: PlaceFactory {
        let factory = PlaceFactory()
        factory.prepareFromCoords(coords: DropinApp.locations.barcelona)
        return factory
    }
    #endif

}
