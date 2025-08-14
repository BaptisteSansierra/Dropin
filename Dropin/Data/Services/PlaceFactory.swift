//
//  PlaceFactory.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/8/25.
//

import SwiftData
import CoreLocation

/// `PlaceFactory` create temporary places which can be manipulated/edited before being saved or discarded
@Observable class PlaceFactory {
        
    private enum CreationMode {
        case coords
        case undefined
    }

    // MARK: - observed vars
    var place: Place
    var buildingPlace: Bool = false

    // MARK: - not observed vars
    @ObservationIgnored private var creationMode: CreationMode = .undefined
    
    // MARK: - init
    init() {
        place = Place()
    }

    // MARK: - public
    func prepareFromCoords(coords: CLLocationCoordinate2D) {
        buildingPlace = true
        creationMode = .coords
        place.coordinates = coords
    }

    func save(modelContext: ModelContext) {
        modelContext.insert(place.toSDPlace())
        reset()
    }
    
    func discard() {
        reset()
    }

    // MARK: - private
    private func reset() {
        place = Place()
        buildingPlace = false
        creationMode = .undefined
    }
}

#if DEBUG
/// Previews purpose
extension PlaceFactory {
    static var preview: PlaceFactory {
        let factory = PlaceFactory()
        factory.prepareFromCoords(coords: DropinApp.locations.barcelona)
        return factory
    }
}
#endif
