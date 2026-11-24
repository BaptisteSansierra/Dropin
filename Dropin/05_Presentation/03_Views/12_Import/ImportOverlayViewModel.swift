//
//  ImportOverlayViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/11/26.
//

import SwiftUI

@MainActor
@Observable class ImportOverlayViewModel {
    
    var presentPrepareView: Bool = false
    var presentBrowseView: Bool = false
    var openFileError: OpenFileError?

    var importStatus: ImportStatus?
    /// A file opened from outside the app is refused while this is true
    var isImporting: Bool { importStatus?.status == .importing }
    /// Set when a Mapstr file with tags has been parsed : triggers MapstrCategoriesView.
    /// Nothing has been written to disk yet at this point.
    var mapstrImportPlan: MapstrImportPlan?

    @ObservationIgnored let onIdle: () -> Void
    @ObservationIgnored let onImportEnded: () -> Void

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var importTask: Task<Void, Never>?
    @ObservationIgnored private var pendingImportCoordinator: ImportCoordinator?

    @ObservationIgnored private var coordinator: ImportFlowCoordinator
    @ObservationIgnored private var saveContext: SaveContext
    @ObservationIgnored private var rollbackContext: RollbackContext
    @ObservationIgnored private var fetchPlaces: FetchPlaces
    @ObservationIgnored private var fetchCategories: FetchCategories
    @ObservationIgnored private var fetchTags: FetchTags
    @ObservationIgnored private var upsertPlace: UpsertPlace
    @ObservationIgnored private var upsertCategory: UpsertCategory
    @ObservationIgnored private var upsertTag: UpsertTag
    @ObservationIgnored private var sync: any SyncServicePausableProtocol

    // MARK: - init
    init(_ appContainer: AppContainer,
         coordinatorMode: ImportFlowCoordinator.Mode,
         saveContext: SaveContext,
         rollbackContext: RollbackContext,
         fetchPlaces: FetchPlaces,
         fetchCategories: FetchCategories,
         fetchTags: FetchTags,
         upsertPlace: UpsertPlace,
         upsertCategory: UpsertCategory,
         upsertTag: UpsertTag,
         sync: any SyncServicePausableProtocol,
         onIdle: @escaping () -> Void,
         onImportEnded: @escaping () -> Void) {
        self.appContainer = appContainer
        self.coordinator = ImportFlowCoordinator(mode: coordinatorMode)
        self.saveContext = saveContext
        self.rollbackContext = rollbackContext
        self.fetchPlaces = fetchPlaces
        self.fetchCategories = fetchCategories
        self.fetchTags = fetchTags
        self.upsertPlace = upsertPlace
        self.upsertCategory = upsertCategory
        self.upsertTag = upsertTag
        self.sync = sync
        self.onIdle = onIdle
        self.onImportEnded = onImportEnded
        
        // Trigger starting flags depending on the mode
        switch coordinatorMode {
            case .openFile(_):
                presentPrepareView = true
            case .openFileError(let error):
                openFileError = error
            case .browse:
                presentBrowseView = true
        }
    }
    
    // MARK: - create subviews
    func createImportPrepareView() -> ImportPrepareView {
        let onCancel = {
            self.dismiss()
        }
        let resolveDestination: (ImportNavigationItem) -> AnyView = { item in
            self.resolveDestination(navigationItem: item)
        }
        return appContainer.createImportPrepareView(coordinator: coordinator,
                                                    onContinue: startImport,
                                                    onCancel: onCancel,
                                                    resolveDestination: resolveDestination)
    }
    
    func createImportSelectorView() -> ImportSelectorView {
        let onCancel = {
            self.dismiss()
        }
        let resolveDestination: (ImportNavigationItem) -> AnyView = { item in
            self.resolveDestination(navigationItem: item)
        }
        return appContainer.createImportSelectorView(coordinator: coordinator,
                                                     onContinue: startImport,
                                                     onCancel: onCancel,
                                                     resolveDestination: resolveDestination)
    }
    
    func createMapstrCategoriesView(onImport: @escaping (CategoryMapping) -> Void) -> MapstrCategoriesView? {
        guard let plan = mapstrImportPlan else { return nil }
        return appContainer.createMapstrCategoriesView(plan: plan, onImport: onImport)
    }

    // MARK: - Navigation
    private func resolveDestination(navigationItem: ImportNavigationItem) -> AnyView {
        switch navigationItem {
            case .categoryMapper:
                return AnyView(createMapstrCategoriesView { mapping in
                    // Dismiss so the user can see the import progression
                    self.revealProgression()
                    self.confirmMapstrCategories(mapping)
                })
        }
    }
    
    func dismiss(waitForAnimation: Bool = true) {
        presentPrepareView = false
        presentBrowseView = false
        openFileError = nil
        Task {
            // Give some time to the dismiss animation
            try await Task.sleep(for: .seconds(waitForAnimation ? 0.5 : 0))
            onIdle()
        }
    }
    
    /// Called when the user tapped `cancel` in ImportStatusView
    /// This does not dismiss anything, only cancel the import task
    func cancelImport() {
        importTask?.cancel()
    }

    /// Called when the user tapped `close` in ImportStatusView
    func closeImport() {
        finalizeImport()
    }
    
    // MARK: - import logic
    private func startImport(url: URL, selectedSource: ImportSource, tagImport: Bool, tagName: String) {
        switch selectedSource {
            case .dropin:
                Task { await self.runImport(source: .dropin, url: url , tagImport: tagImport, tagName: tagName) }
                // We can dismiss now
                self.revealProgression()
            case .mapstr:
                // Do not dismiss still, we'll need to push the tag-to-category view once phase 1 completes
                Task { await self.runImport(source: .mapstr, url: url, tagImport: tagImport, tagName: tagName) }
            case .google:
                Task { await self.runImport(source: .google, url: url, tagImport: tagImport, tagName: tagName) }
                // We can dismiss now
                self.revealProgression()
            default:
                assertionFailure("import source undefined")
                self.dismiss()
        }
    }

    /// Cancel on MapstrCategoriesView: discard the plan, nothing was written.
    private func cancelMapstrCategories() {
        // Confirming also drives mapstrImportPlan to nil, which dismisses the fullScreenCover;
        // SwiftUI then syncs its isPresented binding by calling this a second time — ignore that one,
        // or it wipes the importStatus phase 2 just started populating.
        guard mapstrImportPlan != nil else { return }
        mapstrImportPlan = nil
        pendingImportCoordinator = nil
        importStatus = nil
    }

    /// Confirm on MapstrCategoriesView: proceed to phase 2 with the chosen mapping.
    private func confirmMapstrCategories(_ mapping: CategoryMapping) {
        guard let impCoord = pendingImportCoordinator,
              let plan = mapstrImportPlan else { return }
        mapstrImportPlan = nil
        pendingImportCoordinator = nil
        importTask = Task {
            await runPhase2(impCoord, .mapstr(plan), mapping: mapping, source: .mapstr, filename: importStatus?.filename ?? "")
        }
    }

    private func runImport(source: ImportSource,
                           url: URL,
                           tagImport: Bool,
                           tagName: String) async {
        importStatus = ImportStatus(filename: url.lastPathComponent, source: source)
        do {
            let impCoord = try ImportCoordinator(source: source,
                                                 url: url,
                                                 tagImport: tagImport,
                                                 tagName: tagName,
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
                    coordinator.pushCategoryMapper()
                case .google(let googlePlan):
                    importStatus?.setCount(googlePlan.places.count)
                    await runPhase2(impCoord, plan, mapping: [], source: source, filename: url.lastPathComponent)
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
                // Notify ancestors the import is complete
                // > trigger last import date update
                // > trigger places update in some views
                onImportEnded()
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
    
    private func finalizeImport() {
        importStatus = nil
        importTask = nil
        importStatus = nil
    }
    
    /// Once the import starts dismiss the presented `.fullScreen` views so the ImportStatusView is revealed
    private func revealProgression() {
        presentPrepareView = false
        presentBrowseView = false
    }
}
