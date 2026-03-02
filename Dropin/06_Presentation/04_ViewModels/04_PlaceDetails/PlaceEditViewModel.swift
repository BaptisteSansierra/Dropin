//
//  PlaceEditViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/2/26.
//

import SwiftUI
import ContactFieldKit
import CoreLocation

@MainActor
@Observable class PlaceEditViewModel {
    
    enum Mode {
        case edit
        case creation
    }
    
    var mode: Mode

    @ObservationIgnored private var coordinator: MainCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    //@ObservationIgnored private var locationManager: LocationManager

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         mode: Mode) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.mode = mode
    }
    
    // MARK: Navigation
    
    // MARK: UI Childs
    func createTagSelectorView(place: Binding<PlaceUI>) -> TagSelectorView {
        return appContainer.createTagSelectorView(place: place)
    }
    
    func createGroupSelectorView(place: Binding<PlaceUI>) -> GroupSelectorView {
        return appContainer.createGroupSelectorView(place: place)
    }

    // MARK: - callbacks and co
}
