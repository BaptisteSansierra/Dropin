//
//  SettingsViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/4/26.
//

import SwiftUI

@MainActor
@Observable class SettingsViewModel {
    
    var coordinator: PlaceCoordinator
    
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
    var importStatus: ImportStatus?

    @ObservationIgnored private var importTask: Task<Void, Never>?
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var saveContext: SaveContext
    @ObservationIgnored private var rollbackContext: RollbackContext
    @ObservationIgnored private var fetchPlaces: FetchPlaces
    @ObservationIgnored private var fetchGroups: FetchGroups
    @ObservationIgnored private var fetchTags: FetchTags
    @ObservationIgnored private var upsertPlace: UpsertPlace
    @ObservationIgnored private var upsertGroup: UpsertGroup
    @ObservationIgnored private var upsertTag: UpsertTag
    @ObservationIgnored private var deleteLibrary: DeleteLibrary
    @ObservationIgnored private var sync: any SyncServicePausableProtocol

    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         saveContext: SaveContext,
         rollbackContext: RollbackContext,
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
        self.saveContext = saveContext
        self.rollbackContext = rollbackContext
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

    func importMapstr(_ url: URL) {
        importTask = Task { await runImport(source: .mapstr, url: url) }
    }

    func importDropin(_ url: URL) {
        importTask = Task { await runImport(source: .dropin, url: url) }
    }

    func cancelImport() {
        importTask?.cancel()
    }
    
    func closeImport() {
        importStatus = nil
    }
    
    private func runImport(source: ImportSource, url: URL) async {
        
        // Creating the importStatus triggers showing the ImportStatusView
        importStatus = ImportStatus(filename: url.lastPathComponent,
                                    source: source)
        // Perform the import
        do {
            let impCoord = try ImportCoordinator(source: source,
                                                 url: url,
                                                 saveContext: saveContext,
                                                 rollbackContext: rollbackContext,
                                                 upsertPlace: upsertPlace,
                                                 upsertGroup: upsertGroup,
                                                 upsertTag: upsertTag,
                                                 sync: sync,
                                                 markerTagName: source == .mapstr ? mapstrMarkerTagName : nil)
            try await impCoord.process { count in
                importStatus?.setCount(count)
            } progress: { count in
                guard count > 0 else {
                    importStatus?.setError(.emptyFile)
                    return
                }
                importStatus?.updateProgress(count)
            } canceled: {
                importStatus?.setError(.canceled)
            } completion: { placeCount, duplicatedCount, groupCount, tagCount in
                importStatus?.setDuplicateCount(duplicatedCount)
                importStatus?.setGroupCount(groupCount)
                importStatus?.setTagCount(tagCount)
                importStatus?.complete()
            }
        } catch let error as ImportError {
            Log.error("Import failed (source: \(source), url: \(url.lastPathComponent)): \(error)")
            importStatus?.setError(error)
        } catch {
            Log.error("Import failed (source: \(source), url: \(url.lastPathComponent)): \(error)")
            assertionFailure("unexpected import error \(error)")
            importStatus?.setError(ImportError.unexpectedError(error))
        }
    }
}
