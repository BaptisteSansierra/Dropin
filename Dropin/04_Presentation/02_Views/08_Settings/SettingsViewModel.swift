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
    
    var mapEditMode = MapEditSettingsMode.none

    var importSource: ImportSource = .unknown
    var pickFile = false
    var isImporting = false

    var exportedTemporaryFile: IdentifiableURL?
    var isExporting = false

    var showDeleteConfirmation: Bool = false


    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchPlaces: FetchPlaces
    @ObservationIgnored private var fetchGroups: FetchGroups
    @ObservationIgnored private var fetchTags: FetchTags
    @ObservationIgnored private var upsertPlace: UpsertPlace
    @ObservationIgnored private var upsertGroup: UpsertGroup
    @ObservationIgnored private var upsertTag: UpsertTag
    @ObservationIgnored private var deleteLibrary: DeleteLibrary

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         fetchPlaces: FetchPlaces,
         fetchGroups: FetchGroups,
         fetchTags: FetchTags,
         upsertPlace: UpsertPlace,
         upsertGroup: UpsertGroup,
         upsertTag: UpsertTag,
         deleteLibrary: DeleteLibrary) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.fetchPlaces = fetchPlaces
        self.fetchGroups = fetchGroups
        self.fetchTags = fetchTags
        self.upsertPlace = upsertPlace
        self.upsertGroup = upsertGroup
        self.upsertTag = upsertTag
        self.deleteLibrary = deleteLibrary
    }
    
    func export() async throws -> URL {
        try await ExportService(fetchPlaces: fetchPlaces,
                                fetchGroups: fetchGroups,
                                fetchTags: fetchTags)
            .execute()
    }
    
    func resetDatabase() async throws {
        try await deleteLibrary()
    }

    func importDropin(_ url: URL) async throws {
        let impCoord = try ImportCoordinator(source: .dropin,
                                             url: url,
                                             upsertPlace: upsertPlace,
                                             upsertGroup: upsertGroup,
                                             upsertTag: upsertTag)
        
        try await impCoord.process()
    }
}
