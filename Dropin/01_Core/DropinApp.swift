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

@main
struct DropinApp: App {
    
    // MARK: - App states
    @State private var navigationContext = NavigationContext()
    @State private var mapSettings = MapSettings()

    // MARK: - Properties
    private var appContainer: AppContainer
    private var modelContainer: ModelContainer
    private var locationManager = LocationManager()  // TODO: locationManager could be moved on AppContainer ?

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            appContainer.createRootView()
                .environment(locationManager)
                .environment(navigationContext)
                .environment(mapSettings)
                //.modelContainer(modelContainer)  // DEBUG Purpose, to be removed
                .task {
                    locationManager.start()
                }
        }
    }
        
    // MARK: - init
    init() {
        do {
            let modelContainer = try ModelContainer(for: SDPlace.self, SDTag.self, SDGroup.self)
            modelContainer.mainContext.autosaveEnabled = false
            #if DEBUG
            // If empty database, populate with mock data
            do {
                let places = try modelContainer.mainContext.fetch(FetchDescriptor<SDPlace>())
                if places.count == 0 {
                    print("Empty database, mock populating")
                    try AppContainer.insertMockData(modelContext: modelContainer.mainContext)
                } else {
                    print("\(places.count) places found in database, no mock populate needed")
                }
            } catch {
                print("Couldn't populate database: \(error)")
            }
            #endif
            // Create app container
            appContainer = AppContainer(modelContext: modelContainer.mainContext,
                                        locationManager: locationManager)
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
    struct defaults {
        static let latitude: Double = 46.232193
        static let longitude: Double = 2.209667
        static let latitudeSpan: Double = 10
        static let longitudeSpan: Double = 5
    }
    struct locations {
        static let london = CLLocationCoordinate2D(latitude: 51.5074, longitude: 0.1278)
        static let barcelona = CLLocationCoordinate2D(latitude: 41.390205, longitude: 2.154007)
        static let paris = CLLocationCoordinate2D(latitude: 48.864716, longitude: 2.349014)
        
        /* struct london {
            static let lat: Double = 51.5074
            static let long: Double = 0.1278
        }
        struct barcelona {
            static let lat: Double = 41.390205
            static let long: Double = 2.154007
        }
        struct paris {
            static let lat: Double = 48.864716
            static let long: Double = 2.349014
        } */
    }
    struct ui {
        struct button {
            static let height: Double = 40
            static let width: Double = 200
        }
    }
    struct userDefaultsKeys {
    }
}


#if false
@main
struct DropinApp: App {

    // MARK: - App states
    @State private var modelContainer: ModelContainer
    @State private var navigationContext = NavigationContext()
    @State private var mapSettings = MapSettings()
    @State private var locationManager = LocationManager()
    @State private var placeFactory = PlaceFactory()
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
#if DEBUG
                    //populateDevelopmentDatabase()
#endif
                }
                .accentColor(.dropinSecondary)
        }
        .modelContainer(modelContainer)
        .environment(navigationContext)
        .environment(mapSettings)
        .environment(locationManager)
        .environment(placeFactory)
    }
    
    private func populateDevelopmentDatabase() {
#if DEBUG
        // Add some tags
        for item in SDTag.all {
            modelContainer.mainContext.insert(item)
        }
        // some groups
        for item in SDGroup.all {
            modelContainer.mainContext.insert(item)
        }
        // and some places
        for item in SDPlace.all {
            modelContainer.mainContext.insert(item)
        }
#endif
    }
    
    init() {
        // Configure SwiftData container
        let schema = Schema([SDPlace.self, SDTag.self, SDGroup.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

#endif
