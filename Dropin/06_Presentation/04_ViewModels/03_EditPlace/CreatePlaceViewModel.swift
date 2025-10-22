//
//  CreatePlaceViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 06/10/25.
//

import SwiftUI

// TODO: @Observable could be removed here ?
@MainActor
@Observable class CreatePlaceViewModel {
    
    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let createPlace: CreatePlace
    
    init(_ appContainer: AppContainer, createPlace: CreatePlace) {
        self.appContainer = appContainer
        self.createPlace = createPlace
    }

    // MARK: UI Childs
    func createTagSelectorViewModel(place: Binding<PlaceUI>) -> TagSelectorView {
        return appContainer.createTagSelectorView(place: place)
    }
    
    func createGroupSelectorViewModel(place: Binding<PlaceUI>) -> GroupSelectorView {
        return appContainer.createGroupSelectorView(place: place)
    }

    // MARK: Use cases
    func save(place: PlaceUI) async throws {
        let placeEntity = PlaceMapper.toDomain(place)
        try await createPlace.execute(placeEntity)
    }
}
