//
//  PlaceEditContentViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/2/26.
//

import SwiftUI
import ContactFieldKit
import CoreLocation

@MainActor
@Observable class PlaceEditContentViewModel {
    
    enum Mode {
        case edit
        case creation
    }
    
    @ObservationIgnored var mode: Mode

    @ObservationIgnored private var coordinator: MainCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let updatePlace: UpdatePlace
    @ObservationIgnored private let deletePlace: DeletePlace

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         updatePlace: UpdatePlace,
         deletePlace: DeletePlace,
         mode: Mode) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.updatePlace = updatePlace
        self.deletePlace = deletePlace
        self.mode = mode
    }
    
    // MARK: Navigation
    func popView() {
        coordinator.pop()
    }

    // MARK: UI Childs
    func createTagSelectorView(place: Binding<PlaceUI>) -> TagSelectorView {
        return appContainer.createTagSelectorView(place: place)
    }
    
    func createGroupSelectorView(place: Binding<PlaceUI>) -> GroupSelectorView {
        return appContainer.createGroupSelectorView(place: place)
    }

    // MARK: Use cases
    func updatePlace(_ place: PlaceUI) async throws {
        try await updatePlace.execute(PlaceMapper.toDomain(place))
    }

    func deletePlace(_ place: PlaceUI) async throws {
        try await deletePlace.execute(PlaceMapper.toDomain(place))
        place.databaseDeleted = true
    }

    // MARK: - callbacks and co
}
