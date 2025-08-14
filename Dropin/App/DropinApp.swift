//
//  DropinApp.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/7/25.
//

import SwiftUI
import SwiftData
import CoreLocation

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
