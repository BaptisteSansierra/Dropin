//
//  DropinApp.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/7/25.
//

import SwiftUI
import SwiftData
import CoreLocation
import MapKit
import ContactFieldKit

// Note:
// - 'Infer Sendable for Methods and Key Path Literals' set to Yes to avoid SortDescriptor warning (swift6 concurrency) cf. https://stackoverflow.com/questions/79000052/fetchdescriptor-including-sortdescriptor-returns-warning-in-xcode16


@MainActor
@Observable final class AppContext {
    var currentSideMenuContext: SideMenuContext = .main
}

@main
struct DropinApp: App {
    
    // MARK: - Properties
    private var appContainer: AppContainer
    private var modelContainer: ModelContainer
    private var appSettings = AppSettings()
    private var appContext = AppContext()
    private var reachabilityService = ReachabilityService()

    // MARK: - init
    init() {
        
        // Init Sentry
        DropinTracker.shared.start()
                
        // Create database, wire app
        let schema = Schema([PlaceRecord.self, TagRecord.self, CategoryRecord.self, PlaceImageRecord.self, ProfileRecord.self, SpaceRecord.self])
        let configuration = ModelConfiguration()
        do {
            let modelContainer = try ModelContainer(for: schema, configurations: configuration)
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
            reachabilityService = ReachabilityService()
            
            appContainer = AppContainer(modelContext: modelContainer.mainContext,
                                        appContext: appContext,
                                        reachabilityService: reachabilityService)
            self.modelContainer = modelContainer

        } catch {
            #if DEBUG
            // Creating mock database for Preview/Simulator
            // Is this still usefull ?
            /*
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                let mock = MockContainer()
                appContainer = mock.appContainer
                modelContainer = mock.mockModelContainer
                return
            }
            else if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                let mock = MockContainer()
                appContainer = mock.appContainer
                modelContainer = mock.mockModelContainer
                return
            }
             */
            #endif
            
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
            if let freshContainer = try? ModelContainer(for: schema, configurations: configuration) {
                freshContainer.mainContext.autosaveEnabled = false
                appContainer = AppContainer(modelContext: freshContainer.mainContext, appContext: appContext)
                modelContainer = freshContainer
                Self.configureDependencies()
                return
            }
            #endif
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Configure dependencies
        Self.configureDependencies()
    }

    // MARK: - Body
    var body: some Scene {
        WindowGroup {

            #if false
            MockMapstrCategoriesView()
                .environment(AppSettings())
            #else

            rootContent
                .task {
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
                .onOpenURL { url in
                    guard url.pathExtension == "dropin" else { return }
                    // TODO: handle deep links...
                    //importCoordinator.handle(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Update data when app awakes and user is signedIn
                    switch appContainer.authState {
                        case .signedIn(let signingOut):
                            if signingOut == false {
                                Task { await appContainer.syncAll() }
                            }
                        default:
                            ()
                    }
                }
                .environment(appSettings)
            
            #endif
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch appContainer.authState {
            case .loading:
                SplashView()
            case .signedOut:
                appContainer.createSignInView()
            case .signedIn(let signingOut):
                ZStack {
                    appContainer.createRootView()
                        .task {
                            await appContainer.loadProfile()
                            await appContainer.syncAll()
                        }
                    ZStack {
                        Color.overlayAlphaLayer
                        DropinLoader(style: .overlay, caption: "auth.clearing")
                    }
                    .ignoresSafeArea()
                    .opacity(signingOut ? 1 : 0)
                }
        }
    }

    // MARK: private methods
    static private func configureDependencies() {
        configureContactFieldKit()
    }

    /// Deletes any `.corrupted-*` store backups left behind by a past occurrence of the fallback in `init()`'s catch block.
    /// Called from the healthy-launch path, never from the fallback itself, so cleanup never races the Sentry upload that reported them.
    static private func cleanUpOldCorruptedBackups(near url: URL) {
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
    
    static private func configureContactFieldKit() {
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

// MARK: - app icon utils
extension UIApplication {
    static func setApplicationIconWithoutAlert(_ iconName: String?) {
        guard UIApplication.shared.responds(to: #selector(getter: UIApplication.supportsAlternateIcons)) && UIApplication.shared.supportsAlternateIcons else { return }
        typealias setAlternateIconNameClosure = @convention(c) (NSObject, Selector, NSString?, @escaping (NSError) -> ()) -> ()
        let selectorString = "_setAlternateIconName:completionHandler:"
        let selector = NSSelectorFromString(selectorString)
        let imp = UIApplication.shared.method(for: selector)
        let method = unsafeBitCast(imp, to: setAlternateIconNameClosure.self)
        method(UIApplication.shared, selector, iconName as NSString?, { _ in })
    }
}

// MARK: - app constants
extension DropinApp {
    struct strings {
        static let app = "Dropin"
        static let contact = "contact@dropin.lat"
        static let developer = "Baptiste Sansierra"
        static let exportExtension = "dropin"
        static let exportUTTypeId = "com.dropin.export"
        // redirectTo/emailRedirectTo targets for Supabase auth emails.
        // Web pages for now; will move to the dropin:// scheme (registered in
        // Info.plist's CFBundleURLTypes) once in-app handling is implemented.
        static let resetPasswordURL = URL(string: "https://dropin.lat/reset-password.html")!
        static let emailConfirmedURL = URL(string: "https://dropin.lat/email-confirmed.html")!
    }
    struct defaults {
        static let minimumPasswordLength: Int = 8
    }
    struct map {
        static let mapLabelHideAltitude: Double = 10_000 // meters — labels hidden above this camera altitude
        // static let mapPinDropAltitude: Double = 40_000 // legacy: altitude-based collision drop, superseded by maxDisplayPin
        static let maxDisplayPin: Int = 30 // max number of full (SwiftUI) pins shown at once; remaining visible places render as dots
        static let declutterRefreshDebounce: Double = 0.2 // seconds of no camera movement before pin/dot + label state is refreshed
        static let usePinPromotionLogic = false
        // When set, the map always launches on this region instead of centering on the user. Used for app screenshots
        static let hardStartRegion: MKCoordinateRegion? = nil
        /* Lisbon center : used for screenshots generation
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.71108482247233, longitude: -9.137567732050831),
            span: MKCoordinateSpan(latitudeDelta: 0.02649615024206753, longitudeDelta: 0.020133175667885084)
        )
         */
    }
    struct ui {
        static let mainTabBarHeight: CGFloat = 80
        struct button {
            static let height: Double = 52
            static let smallHeight: Double = 42
            //static let width: Double = 200
        }
        static let addressPickerSheetHeight: CGFloat = 400
        //static let pinHeight: CGFloat = 36 // Height of the pins displayed on the map
    }
    struct storage {
        static let thumbnailSize: CGFloat = 400
        static let thumbnailCompression: CGFloat = 0.7
        static let imageMaxSize: CGFloat = 1200
        static let imageMaxDiskSize: Int = 150_000  // 150KB
    }
    struct userDefaultsKeys {
        static let pinStyle = "settings.map.pinStyle"
        static let pinSize = "settings.map.pinSize"
        static let mapType = "settings.map.mapType"
        static let poiConfig = "settings.map.poiConfig"
        static let clustering = "settings.map.clustering"
        static let lastSyncedAt = "service.sync.last"
        static let currentSpaceId = "space.current"
    }
}
