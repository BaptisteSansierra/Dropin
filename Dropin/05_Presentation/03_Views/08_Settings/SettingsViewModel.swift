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

    /// Set when a Mapstr file with tags has been parsed — triggers MapstrCategoriesView.
    /// Nothing has been written to disk yet at this point.
    var mapstrImportPlan: MapstrImportPlan?

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
    @ObservationIgnored private var fetchCategories: FetchCategories
    @ObservationIgnored private var fetchTags: FetchTags
    @ObservationIgnored private var upsertPlace: UpsertPlace
    @ObservationIgnored private var upsertCategory: UpsertCategory
    @ObservationIgnored private var upsertTag: UpsertTag
    @ObservationIgnored private var deleteLibrary: DeleteLibrary
    @ObservationIgnored private var sync: any SyncServicePausableProtocol

    @ObservationIgnored private var pendingImportCoordinator: ImportCoordinator?

    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         saveContext: SaveContext,
         rollbackContext: RollbackContext,
         fetchPlaces: FetchPlaces,
         fetchCategories: FetchCategories,
         fetchTags: FetchTags,
         upsertPlace: UpsertPlace,
         upsertCategory: UpsertCategory,
         upsertTag: UpsertTag,
         deleteLibrary: DeleteLibrary,
         sync: any SyncServicePausableProtocol) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.saveContext = saveContext
        self.rollbackContext = rollbackContext
        self.fetchPlaces = fetchPlaces
        self.fetchCategories = fetchCategories
        self.fetchTags = fetchTags
        self.upsertPlace = upsertPlace
        self.upsertCategory = upsertCategory
        self.upsertTag = upsertTag
        self.deleteLibrary = deleteLibrary
        self.sync = sync
    }

    func export() async throws -> URL {
        try await ExportService(fetchPlaces: fetchPlaces,
                                fetchCategories: fetchCategories,
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

    /// Cancel on MapstrCategoriesView: discard the plan, nothing was written.
    func cancelMapstrCategories() {
        // Confirming also drives mapstrImportPlan to nil, which dismisses the fullScreenCover;
        // SwiftUI then syncs its isPresented binding by calling this a second time — ignore that one,
        // or it wipes the importStatus phase 2 just started populating.
        guard mapstrImportPlan != nil else { return }
        mapstrImportPlan = nil
        pendingImportCoordinator = nil
        importStatus = nil
    }

    /// Confirm on MapstrCategoriesView: proceed to phase 2 with the chosen mapping.
    func confirmMapstrCategories(_ mapping: CategoryMapping) {
        guard let impCoord = pendingImportCoordinator,
              let plan = mapstrImportPlan else { return }
        mapstrImportPlan = nil
        pendingImportCoordinator = nil
        importTask = Task {
            await runPhase2(impCoord, .mapstr(plan), mapping: mapping, source: .mapstr, filename: importStatus?.filename ?? "")
        }
    }

    func createMapstrCategoriesView(onImport: @escaping (CategoryMapping) -> Void) -> MapstrCategoriesView? {
        guard let plan = mapstrImportPlan else { return nil }
        return appContainer.createMapstrCategoriesView(plan: plan, onImport: onImport)
    }

    private func runImport(source: ImportSource, url: URL) async {
        importStatus = ImportStatus(filename: url.lastPathComponent, source: source)
        do {
            let impCoord = try ImportCoordinator(source: source,
                                                 url: url,
                                                 saveContext: saveContext,
                                                 rollbackContext: rollbackContext,
                                                 fetchPlaces: fetchPlaces,
                                                 fetchCategories: fetchCategories,
                                                 fetchTags: fetchTags,
                                                 upsertPlace: upsertPlace,
                                                 upsertCategory: upsertCategory,
                                                 upsertTag: upsertTag,
                                                 sync: sync)
            let plan = try await impCoord.readPlan()
            switch plan {
                case .dropin(let export):
                    importStatus?.setCount(export.places.count)
                    await runPhase2(impCoord, plan, mapping: [], source: source, filename: url.lastPathComponent)
                case .mapstr(let mapstrPlan) where mapstrPlan.tags.isEmpty:
                    importStatus?.setCount(mapstrPlan.places.count)
                    await runPhase2(impCoord, plan, mapping: [], source: source, filename: url.lastPathComponent)
                case .mapstr(let mapstrPlan):
                    importStatus?.setCount(mapstrPlan.places.count)
                    pendingImportCoordinator = impCoord
                    mapstrImportPlan = mapstrPlan
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

    private func runPhase2(_ impCoord: ImportCoordinator,
                           _ plan: ImportPlan,
                           mapping: CategoryMapping,
                           source: ImportSource,
                           filename: String) async {
        do {
            try await impCoord.importPlan(plan, mapping: mapping) { count in
                self.importStatus?.updateProgress(count)
            } canceled: {
                self.importStatus?.setError(.canceled)
            } completion: { placeCount, duplicatedCount, categoryCount, tagCount in
                self.importStatus?.setDuplicateCount(duplicatedCount)
                self.importStatus?.setCreatedPlaceCount(placeCount)
                self.importStatus?.setCreatedCategoryCount(categoryCount)
                self.importStatus?.setCreatedTagCount(tagCount)
                self.importStatus?.complete()
            }
        } catch let error as ImportError {
            Log.error("Import failed (source: \(source), url: \(filename)): \(error)")
            importStatus?.setError(error)
        } catch {
            Log.error("Import failed (source: \(source), url: \(filename)): \(error)")
            assertionFailure("unexpected import error \(error)")
            importStatus?.setError(ImportError.unexpectedError(error))
        }
    }
}
