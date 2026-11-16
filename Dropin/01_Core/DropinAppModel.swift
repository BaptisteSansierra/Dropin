//
//  DropinAppModel.swift
//  Dropin
//

import SwiftUI
import SwiftData
import ContactFieldKit

/// App-level logic behind DropinApp: storage + dependencies setup, launch, incoming URLs
@MainActor
@Observable final class DropinAppModel {

    // MARK: - Properties
    @ObservationIgnored let appContainer: AppContainer
    @ObservationIgnored let appSettings = AppSettings()
    @ObservationIgnored private let appContext: AppContext
    @ObservationIgnored private let modelContainer: ModelContainer

    /// File opened from outside the app (Files, AirDrop, Mail...) before the sign in, presented once the user is signed in
    //@ObservationIgnored private var waitingImport: PendingImport?
    @ObservationIgnored private var waitingImportURL: URL?


    private var isSignedIn: Bool {
        if case .signedIn(signingOut: false) = appContainer.authState { return true }
        return false
    }

    // MARK: - init
    init() {
        self.appContext = AppContext()

        #if DEBUG
        if ScreenshotMode.isOn {
            let schema = Schema([PlaceRecord.self, TagRecord.self, CategoryRecord.self, PlaceImageRecord.self, ProfileRecord.self, SpaceRecord.self])
            let container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            container.mainContext.autosaveEnabled = false
            let locationManager = LocationManager()
            modelContainer = container
            appContainer = AppContainer(modelContext: container.mainContext,
                                        appContext: appContext,
                                        locationManager: locationManager,
                                        addressLookupService: AddressLookupService(locationManager: locationManager),
                                        reachabilityService: StubReachabilityService(),
                                        profileService: StubProfileService(),
                                        authService: StubAuthService(restoredSession: .johnDoe))
            configureDependencies()
            return
        }
        #endif

        // Init Sentry
        DropinTracker.shared.start()

        // Create database, wire app
        let schema = Schema([PlaceRecord.self,
                             TagRecord.self,
                             CategoryRecord.self,
                             PlaceImageRecord.self,
                             ProfileRecord.self,
                             SpaceRecord.self])
        let configuration = ModelConfiguration()
        do {
            let modelContainer = try ModelContainer(for: schema,
                                                    migrationPlan: DropinMigrationPlan.self,
                                                    configurations: configuration)
            modelContainer.mainContext.autosaveEnabled = false
            // Healthy launch: let's clean up backups left behind by a past occurrence of corrupted-store
            Self.cleanUpOldCorruptedBackups(near: configuration.url)
            #if DEBUG
            // If empty database, populate with mock data
            if false {
                do {
                    let places = try modelContainer.mainContext.fetch(FetchDescriptor<PlaceRecord>())
                    if places.count == 0 {
                        Log.info("Empty database, mock populating")
                        try AppContainer.insertMockData(modelContext: modelContainer.mainContext)
                    } else {
                        Log.info("\(places.count) places found in database, no mock populate needed")
                    }
                } catch {
                    Log.error("Couldn't populate database: \(error)")
                }
            }
            // Create data from cata OpenData
            if false {
                Task {
                    do {
                        Log.info("Load Cat open data")
                        let catOpenData = try CatOpenData(modelContext: modelContainer.mainContext)
                        try await catOpenData.load()
                    } catch {
                        fatalError("Error while getting dummy openData: \(error)")
                    }
                }
            }
            #endif

            // Create app container
            appContainer = AppContainer(modelContext: modelContainer.mainContext,
                                        appContext: appContext,
                                        reachabilityService: ReachabilityService())
            self.modelContainer = modelContainer

        } catch {
            #if !DEBUG
            // Last resort: the store couldn't be opened against the current schema (an
            // unmigrated schema change slipped through, a corrupted store, etc).
            // By the time this ships, schema changes are expected to carry a real migration plan, so this shouldn't normally trigger;
            // this only exists so a stale/incompatible store doesn't permanently brick the app for a user.
            // Backup it and start clean rather than crash-looping forever.
            Log.error("ModelContainer failed (\(error)) -> backing up store and starting fresh")
            let backupSuffix = ".corrupted-\(Int(Date().timeIntervalSince1970))"
            var backupURLs: [URL] = []
            for suffix in ["", "-wal", "-shm"] {
                let source = URL(fileURLWithPath: configuration.url.path + suffix)
                let backup = URL(fileURLWithPath: configuration.url.path + suffix + backupSuffix)
                if (try? FileManager.default.moveItem(at: source, to: backup)) != nil {
                    backupURLs.append(backup)
                }
            }
            // So this fallback is actually diagnosable instead of just inert: attach the backed-up store files to the event
            // small (in-memory-sized) local SQLite files, well under Sentry's attachment size limit.
            DropinTracker.shared.captureWithFiles(error, urls: backupURLs)

            // Backup is left on disk; a future healthy launch will clean up (see cleanUpOldCorruptedBackups)
            if let freshContainer = try? ModelContainer(for: schema,
                                                        migrationPlan: DropinMigrationPlan.self,
                                                        configurations: configuration) {
                freshContainer.mainContext.autosaveEnabled = false
                appContainer = AppContainer(modelContext: freshContainer.mainContext,
                                            appContext: appContext,
                                            reachabilityService: ReachabilityService())
                modelContainer = freshContainer
                configureDependencies()
                return
            }
            #endif
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Configure dependencies
        configureDependencies()
    }

    // MARK: - App events
    func launch() async {
        #if DEBUG
        if ScreenshotMode.isOn {
            if let seedURL = ScreenshotMode.seedURL {
                await appContainer.importScreenshotSeed(from: seedURL)
            }
            appContainer.startLocationManager()   // authorized + positioned by scripts/screenshots.sh (simctl)
            await appContainer.restoreSession()
            return
        }
        #endif

        appContainer.startLocationManager()
        await appContainer.restoreSession()

#if false
        // *** Dropin Icons generator ***
        //
        // Make it true, it will generate and save the Dropin icons & Logo assets
        //
        // FIXME: this should be moved outside the app in a specific target

        // Generate
        IcoRenderer(variant: .logo)
        IcoRenderer(variant: .variant1)
        IcoRenderer(variant: .variant2)
        IcoRenderer(variant: .variant3)
        IcoRenderer(variant: .logo, colorScheme: .dark, bgColor: .black)
        IcoRenderer(variant: .variant1, colorScheme: .dark, bgColor: .black)
        IcoRenderer(variant: .variant2, colorScheme: .dark, bgColor: .black)
        IcoRenderer(variant: .variant3, colorScheme: .dark, bgColor: .black)

        IcoRenderer(variant: .logo, imageSize: 300, bgColor: .clear)
        IcoRenderer(variant: .logo, colorScheme: .dark, imageSize: 300, bgColor: .clear)
#endif
    }

    func willEnterForeground() {
        // Update data when app awakes and user is signedIn
        guard isSignedIn else { return }
        Task { await appContainer.syncAll() }
    }

    func open(_ url: URL) {
        if url.isFileURL {
            openFile(url)
        } else if url.scheme == AppConfig.scheme {
            openDeepLink(url)
        } else {
            openUniversalLink(url)
        }
    }

    // MARK: - Opened file
    /// Called on sign in / sign out: an import waiting since a cold launch is presented to a signed in user only,
    /// a sign out closes the presented one
    func updateImportPresentation() {
        guard isSignedIn else {
            //appContainer.importPresenter.cancel()
            appContainer.importPresenter.presentError(.loggedOut)
            return
        }
        guard let pendingImport = waitingImportURL else { return }
        waitingImportURL = nil
        appContainer.importPresenter.presentFile(pendingImport)
    }

    // MARK: - Private
    private func openFile(_ url: URL) {
        // Checked before the copy: it empties the inbox, which holds the file being imported
        guard !appContainer.importPresenter.isImporting else {
            presentImportError(.importInProgress)
            return
        }
        Task {
            do {
                // Off the main thread: an iCloud file may need to be downloaded first
                let copy = try await Task.detached { try Self.copyToImportInbox(url) }.value
                waitingImportURL = copy
                updateImportPresentation()
            } catch {
                Log.error("Couldn't copy the opened file \(url.lastPathComponent): \(error)")
                presentImportError(.unreadable(url.lastPathComponent))
            }
        }
    }

    private func presentImportError(_ error: OpenFileError) {
        appContainer.importPresenter.presentError(error)
    }

    private func openDeepLink(_ url: URL) {
        Log.warning("TODO: handle deep link")
        assertionFailure("handle deep link")
    }

    private func openUniversalLink(_ url: URL) {
        Log.warning("TODO: handle universal link")
        assertionFailure("handle universal link")
    }

    // MARK: - static private methods

    /// iOS hands over the user's own file (LSSupportsOpeningDocumentsInPlace), readable only while its security scope is open:
    /// work on a local copy, kept until the next opened file
    nonisolated private static func copyToImportInbox(_ url: URL) throws -> URL {
        // false for a file iOS already copied into the app (AirDrop, Mail: Documents/Inbox), readable as is
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let inbox = FileManager.default.temporaryDirectory.appending(path: "ImportInbox", directoryHint: .isDirectory)
        try? FileManager.default.removeItem(at: inbox)   // one pending import at a time
        try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        let copy = inbox.appending(path: url.lastPathComponent)

        // Coordinated read: downloads an iCloud file that isn't on the device yet
        var coordinationError: NSError?
        var copyError: Error?
        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinationError) { readURL in
            do {
                try FileManager.default.copyItem(at: readURL, to: copy)
            } catch {
                copyError = error
            }
        }
        if let error = coordinationError ?? copyError { throw error }
        return copy
    }

    private func configureDependencies() {
        appContainer.importPresenter.appSettings = appSettings
        Self.configureContactFieldKit()
    }

    /// Deletes any `.corrupted-*` store backups left behind by a past occurrence of the fallback in `init()`'s catch block.
    /// Called from the healthy-launch path, never from the fallback itself, so cleanup never races the Sentry upload that reported them.
    private static func cleanUpOldCorruptedBackups(near url: URL) {
        let directory = url.deletingLastPathComponent()
        let baseName = url.lastPathComponent
        guard let contents = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for fileURL in contents {
            let name = fileURL.lastPathComponent
            if name.hasPrefix(baseName), name.contains(".corrupted-") {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    private static func configureContactFieldKit() {
        ContactFieldUIConfig.backgroundPrimary = .surface1
        ContactFieldUIConfig.backgroundSecondary = .surface2
        ContactFieldUIConfig.backgroundTertiary = .backgroundPrimary

        ContactFieldUIConfig.textPrimaryColor = .textTertiary

        ContactFieldUIConfig.bodyTextFont = Font.bodyRegular
        ContactFieldUIConfig.captionTextFont = Font.captionRegular

        ContactFieldUIConfig.success = .dropinPrimary
        ContactFieldUIConfig.destructive = .destructive

        ContactFieldUIConfig.topDivider = .clear
        ContactFieldUIConfig.bottomDivider = .clear
    }
}
