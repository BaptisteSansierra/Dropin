//
//  DropinApp.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/7/25.
//

import SwiftUI
import SwiftData
import CoreLocation

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

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            rootContent
                .task {
                    appContainer.startLocationManager()
                    await appContainer.restoreSession()

#if false
                    // Enable to generate new AppIcons + logo assets
                    // TODO: this should be moved outside the app in a specific target
                    
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
                    // TODO
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
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch appContainer.authState {
            case .loading:
                SplashView()
            case .signedOut:
                appContainer.createAuthView()
            case .signedIn(let signingOut):
                ZStack {
                    appContainer.createRootView()
                        .task {
                            await appContainer.loadProfile()
                            await appContainer.syncAll()
                        }
                    ZStack {
                        Color.overlayAlphaLayer
                        DropinLoader(style: .overlay, caption: "Clearing session")
                    }
                    .ignoresSafeArea()
                    .opacity(signingOut ? 1 : 0)
                }
        }
    }

    // MARK: - init
    init() {
        do {
            let modelContainer = try ModelContainer(for: SDPlace.self, SDTag.self, SDGroup.self, SDImage.self, SDProfile.self)
            modelContainer.mainContext.autosaveEnabled = false
            #if DEBUG
            // If empty database, populate with mock data
            if false {
                do {
                    let places = try modelContainer.mainContext.fetch(FetchDescriptor<SDPlace>())
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
                                        appContext: appContext)
            self.modelContainer = modelContainer

        } catch {
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
            fatalError("Could not create ModelContainer: \(error)")
        }
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
        static let developer = "Baptiste Sansierra"
        static let exportExtension = "dropin"
        static let exportUTTypeId = "com.dropin.export"
    }
    struct defaults {
        static let latitude: Double = 46.232193
        static let longitude: Double = 2.209667
        static let latitudeSpan: Double = 10
        static let longitudeSpan: Double = 5
    }
    struct ui {
        static let mainTabBarHeight: CGFloat = 80
        struct button {
            static let height: Double = 40
            static let width: Double = 200
        }
        static let addressPickerSheetHeight: CGFloat = 225
        static let coordinatesPickerSheetHeight: CGFloat = 300
        //static let pinHeight: CGFloat = 36 // Height of the pins displayed on the map
        static let mapLabelHideAltitude: Double = 10_000 // meters — labels hidden above this camera altitude
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
        static let hidePOI = "settings.map.hidePOI"
        static let satellite = "settings.map.satellite"
        static let clustering = "settings.map.clustering"
        static let lastSyncedAt = "service.sync.last"
    }
}
