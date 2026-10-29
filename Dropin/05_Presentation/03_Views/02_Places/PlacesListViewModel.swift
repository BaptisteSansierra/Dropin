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
    var searchText: String = ""
    var syncStatus: SyncStatus

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored let locationManager: LocationManager
    
    // MARK: Init
    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         locationManager: LocationManager,
         syncStatus: SyncStatus) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.locationManager = locationManager
        self.syncStatus = syncStatus
    }
    
    func searchedPlaces(_ places: [PlaceUIModel]) -> [PlaceUIModel] {
        let normalizedSearchText = searchText.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        guard !normalizedSearchText.isTrimmedEmpty else {
            return places.filter { return $0.isActive }
        }
        return places.filter { place in
            guard place.isActive else { return false }
            let normName = place.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            if normName.contains(normalizedSearchText) {
                return true
            }
            if let address = place.address {
                let normAddr = address.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                if normAddr.contains(normalizedSearchText) {
                    return true
                }
            }
            return false
        }
    }
}
