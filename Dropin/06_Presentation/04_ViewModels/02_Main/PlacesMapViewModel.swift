//
//  PlacesMapViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation
import CoreLocation

@MainActor
@Observable class PlacesMapViewModel {
    
    private enum CreationMode {
        case coords
        case undefined
    }

    // MARK: Properties
    var places: [PlaceEntity] = [PlaceEntity]()
    var tmpPlace: PlaceEntity? = nil   // Used for creating a new place
    /// `pinPlace` is defined when a place annotation is selected on the map, toggle the corresponding sheet
    var pinPlace: PlaceEntity?


    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let getPlaces: GetPlaces
    @ObservationIgnored private let createPlace: CreatePlace
    @ObservationIgnored private var creationMode: CreationMode = .undefined  // TODO: to be used ?
    //@ObservationIgnored private let deletePlace: DeletePlace
    
    init(_ appContainer: AppContainer, getPlaces: GetPlaces, createPlace: CreatePlace) {
        self.appContainer = appContainer
        self.getPlaces = getPlaces
        self.createPlace = createPlace
    }
    
    func loadPlaces() async throws {
        places = try await getPlaces.execute()
    }
    
    func preparePlaceFromCoords(coords: CLLocationCoordinate2D) -> PlaceEntity {
        creationMode = .coords
        let createdPlace = PlaceEntity(coordinates: coords)
        tmpPlace = createdPlace
        return createdPlace
    }
    
    // MARK: - private
    private func reset() {
        tmpPlace = nil
        //buildingPlace = false
        creationMode = .undefined
    }
}
