//
//  PlacesListViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable class PlacesListViewModel {
    
    // MARK: Properties
    private(set) var coordinator: PlaceCoordinator
    var searchText = ""

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored let locationManager: LocationManager
    
    // MARK: Init
    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         locationManager: LocationManager) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
    }
}
