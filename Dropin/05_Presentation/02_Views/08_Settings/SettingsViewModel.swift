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
    var showMapstrConfig = false
    var mapstrMarkerTagName: String = "Mapstr"

    var exportedTemporaryFile: IdentifiableURL?
    var isExporting = false

    var showDeleteConfirmation: Bool = false
    
    var importing: Bool = false
    var importingCaption: LocalizedStringKey = ""

    enum ImportResult: Equatable {
        case success(count: Int)
        case failure(message: String)
    }
    var importResult: ImportResult?

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchPlaces: FetchPlaces
    @ObservationIgnored private var fetchGroups: FetchGroups
    @ObservationIgnored private var fetchTags: FetchTags
    @ObservationIgnored private var upsertPlace: UpsertPlace
    @ObservationIgnored private var upsertGroup: UpsertGroup
    @ObservationIgnored private var upsertTag: UpsertTag
    @ObservationIgnored private var deleteLibrary: DeleteLibrary
    @ObservationIgnored private var sync: any SyncServicePausableProtocol

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         fetchPlaces: FetchPlaces,
         fetchGroups: FetchGroups,
         fetchTags: FetchTags,
         upsertPlace: UpsertPlace,
         upsertGroup: UpsertGroup,
         upsertTag: UpsertTag,
         deleteLibrary: DeleteLibrary,
         sync: any SyncServicePausableProtocol) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.fetchPlaces = fetchPlaces
        self.fetchGroups = fetchGroups
        self.fetchTags = fetchTags
        self.upsertPlace = upsertPlace
        self.upsertGroup = upsertGroup
        self.upsertTag = upsertTag
        self.deleteLibrary = deleteLibrary
        self.sync = sync
    }
    
    func export() async throws -> URL {
        try await ExportService(fetchPlaces: fetchPlaces,
                                fetchGroups: fetchGroups,
                                fetchTags: fetchTags)
            .execute()
    }
    
    func resetDatabase() async throws {
        try await sync.withPausedPushes {
            try await deleteLibrary()
        }
    }

    func importMapstr(_ url: URL) async {
        await runImport(source: .mapstr, url: url)
    }

    func importDropin(_ url: URL) async {
        await runImport(source: .dropin, url: url)
    }

    private func runImport(source: ImportSource, url: URL) async {
        importing = true
        importingCaption = "settings.importing"
        defer {
            importing = false
            importingCaption = ""
        }
        do {
            let impCoord = try ImportCoordinator(source: source,
                                                 url: url,
                                                 upsertPlace: upsertPlace,
                                                 upsertGroup: upsertGroup,
                                                 upsertTag: upsertTag,
                                                 sync: sync,
                                                 markerTagName: source == .mapstr ? mapstrMarkerTagName : nil)
            try await impCoord.process { count in
                self.importingCaption = "settings.importing_count_\(count)"
            } completion: { count in
                self.importResult = .success(count: count)
            }
        } catch {
            Log.error("Import failed (source: \(source), url: \(url.lastPathComponent)): \(error)")
            importResult = .failure(message: error.localizedDescription)
        }
    }
}
