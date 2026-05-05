//
//  PlaceEditViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/3/26.
//

import SwiftUI
import ContactFieldKit
import CoreLocation

@MainActor
@Observable class PlaceEditViewModel {
    
    @ObservationIgnored private var coordinator: MainCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let updatePlace: UpdatePlace

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         updatePlace: UpdatePlace) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.updatePlace = updatePlace
    }
    
    // MARK: Navigation
    func pop() {
        coordinator.pop()
    }

    // MARK: UI Childs
    func body(place: Binding<PlaceUI>, showMissingName: Binding<Bool>) -> some View {
        return appContainer.createPlaceEditContentView(place: place,
                                                       mode: .edit,
                                                       showMissingName: showMissingName)
    }

    // MARK: Use cases
    func updatePlace(_ place: PlaceUI) async throws {
        try await updatePlace(PlaceMapper.toDomain(place))
    }
    
    // MARK: - callbacks and co
}
