//
//  SettingsViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/4/26.
//

import SwiftUI

@MainActor
@Observable class SettingsViewModel {
    
    var coordinator: MainCoordinator

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchPlaces: FetchPlaces
    @ObservationIgnored private var fetchGroups: FetchGroups
    @ObservationIgnored private var fetchTags: FetchTags

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         fetchPlaces: FetchPlaces,
         fetchGroups: FetchGroups,
         fetchTags: FetchTags) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.fetchPlaces = fetchPlaces
        self.fetchGroups = fetchGroups
        self.fetchTags = fetchTags
    }
    
    func export() async throws {
        try await ExportService(fetchPlaces: fetchPlaces,
                                getGroups: fetchGroups,
                                getTags: fetchTags)
            .execute()
    }
}
