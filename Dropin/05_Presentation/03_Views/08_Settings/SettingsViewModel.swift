//
//  SettingsViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/4/26.
//

import SwiftUI

@MainActor
@Observable class SettingsViewModel {

    var mapEditMode = MapEditSettingsMode.none
    var exportedTemporaryFile: IdentifiableURL?
    var isExporting = false
    var showDeleteConfirmation: Bool = false
    var genericError: GenericError? = nil
    var coordinator: SettingsCoordinator

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchPlaces: FetchPlaces
    @ObservationIgnored private var fetchCategories: FetchCategories
    @ObservationIgnored private var fetchTags: FetchTags
    @ObservationIgnored private var importPresenter: ImportPresenter
    @ObservationIgnored private var deleteLibrary: DeleteLibrary
    @ObservationIgnored private var sync: any SyncServicePausableProtocol

    init(_ appContainer: AppContainer,
         coordinator: SettingsCoordinator,
         importPresenter: ImportPresenter,
         fetchPlaces: FetchPlaces,
         fetchCategories: FetchCategories,
         fetchTags: FetchTags,
         deleteLibrary: DeleteLibrary,
         sync: any SyncServicePausableProtocol) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.importPresenter = importPresenter
        self.fetchPlaces = fetchPlaces
        self.fetchCategories = fetchCategories
        self.fetchTags = fetchTags
        self.deleteLibrary = deleteLibrary
        self.sync = sync
    }

    // MARK: - navigation
    func presentImport() {
        importPresenter.presentBrowse()
    }

    // MARK: - actions
    func export() async {
        isExporting = true
        exportedTemporaryFile = nil
        defer { isExporting = false }
        do {
            let url = try await ExportService(fetchPlaces: fetchPlaces,
                                              fetchCategories: fetchCategories,
                                              fetchTags: fetchTags).execute()
            exportedTemporaryFile = IdentifiableURL(url: url)
        } catch is CancellationError {
            // ignore silently
        } catch let error as EncodingError {
            genericError = .encoding(error)
        } catch let error as CocoaError where error.code == .fileWriteOutOfSpace {
            genericError = .noDiskSpace(error)
        } catch {
            genericError = .unexpected(error)
        }
    }

    func resetDatabase() async throws {
        try await sync.withPausedPushes {
            try await deleteLibrary()
        }
    }
}
