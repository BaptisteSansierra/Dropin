//
//  MainViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable class MainViewModel {
    
    var places: [PlaceUI] = [PlaceUI]()
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var getPlaces: GetPlaces
    
    init(_ appContainer: AppContainer, getPlaces: GetPlaces) {
        self.appContainer = appContainer
        self.getPlaces = getPlaces
    }
    
    // MARK: UI Child
    func createPlacesMapView() -> PlacesMapView {
        let bindingPlaces = Binding<[PlaceUI]>(
            get: {
                return self.places
            }, set: { value in
                self.places = value
            })
        return appContainer.createPlacesMapView(places: bindingPlaces)
    }
    
    func createPlacesListView() -> PlacesListView {
        let bindingPlaces = Binding<[PlaceUI]>(
            get: {
                return self.places
            }, set: { value in
                self.places = value
            })
        return appContainer.createPlacesListView(places: bindingPlaces)
    }
    
    func createPlaceDetailsView(place: Binding<PlaceUI>, editMode: PlaceEditMode) -> PlaceDetailsView {
        return appContainer.createPlaceDetailsView(place: place, editMode: editMode)
    }
    
    // MARK: Use cases
    func loadPlaces() async throws {
        let domainPlaces = try await getPlaces.execute()
        places = domainPlaces.map { PlaceMapper.toUI($0) }
    }
}
