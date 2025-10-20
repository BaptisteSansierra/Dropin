//
//  PlacesMapViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation
import CoreLocation
import SwiftUI

struct PlaceID: Identifiable, Equatable {
    let id: String
}

@MainActor
@Observable class PlacesMapViewModel {
    
    private enum CreationMode {
        case coords
        case undefined
    }

    // MARK: Properties
    //var places: [PlaceUI] = [PlaceUI]()
    var tmpPlace: PlaceUI? = nil   // Used for creating a new place
    /// `selectedPlaceId` is defined when a place annotation is selected on the map, toggle the corresponding sheet
    var selectedPlaceId: PlaceID? {
        didSet {
//            guard let selectedPlaceId = selectedPlaceId else { return }
//            if places.firstIndex(where: { $0.id == selectedPlaceId.id }) == nil {
//                assertionFailure("no place found related to selectedPlaceId: \(selectedPlaceId)")
//                self.selectedPlaceId = nil
//            }
        }
    }

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
    
    func preparePlaceFromCoords(coords: CLLocationCoordinate2D) -> PlaceUI {
        creationMode = .coords
        let createdPlace = PlaceUI(coordinates: coords)
        tmpPlace = createdPlace
        return createdPlace
    }
    
    func discardCreation() {
        reset()
    }
    
    // MARK: - UI child
    func createCreatePlacesView() -> CreatePlaceView {
        guard let tmpPlace = tmpPlace else {
            fatalError("temporary place undefined")
        }
        return appContainer.createCreatePlaceView(place: tmpPlace)
    }
        
    func createPlaceDetailsSheetView(place: Binding<PlaceUI>) -> PlaceDetailsSheetView {
        return appContainer.createPlaceDetailsSheetView(place: place)
    }

    // MARK: - Use cases
    func loadPlaces() async throws -> [PlaceUI] {
        let domainPlaces = try await getPlaces.execute()
        let places = domainPlaces.map { PlaceMapper.toUI($0) }
        // check selectedPlaceId is nil or valid after loading places
        if let selectedPlaceId = selectedPlaceId {
            if places.firstIndex(where: { $0.id == selectedPlaceId.id }) == nil {
                self.selectedPlaceId = nil
            }
        }
        return places
    }

    // MARK: - private
    private func reset() {
        tmpPlace = nil
        //buildingPlace = false
        creationMode = .undefined
    }
}
