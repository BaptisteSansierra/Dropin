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
    
    // MARK: - Properties
    private var appContainer: AppContainer
    private var modelContainer: ModelContainer

    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            appContainer.createRootView()
                .task {
                    appContainer.startLocationManager()

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
            
            // Create data from cata OpenData
            if false {
                Task {
                    do {
                        print("Load Cat open data")
                        let catOpenData = try CatOpenData(modelContext: modelContainer.mainContext)
                        try await catOpenData.load()
                    } catch {
                        fatalError("Error while getting dummy openData: \(error)")
                    }
                }
            }
            
            #endif
            
            // Create app container
            appContainer = AppContainer(modelContext: modelContainer.mainContext)
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
        static let mapHidePointsOfInterest = "map.hidePointsOfInterest"
        static let mapSatellite = "map.satellite"
    }
}
