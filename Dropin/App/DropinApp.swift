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

    @State private var modelContainer: ModelContainer

    @State private var appNavigationContext = AppNavigationContext()
    
    @State private var mapSettings = MapSettings()

    @State private var locationManager = LocationManager()
    
    @State private var placeFactory = PlaceFactory()
    
    
    var body: some Scene {
        WindowGroup {
            //MainView()
            RootView()
                .onAppear {
#if DEBUG
                    //populateDevelopmentDatabase()
#endif
                }
                .accentColor(.dropinSecondary)
        }
        .modelContainer(modelContainer)
        .environment(locationManager)
        .environment(appNavigationContext)
        .environment(mapSettings)
        .environment(placeFactory)
    }
    
    private func populateDevelopmentDatabase() {
#if DEBUG
        modelContainer.mainContext.insert(SDTag.t1)
        modelContainer.mainContext.insert(SDTag.t2)
        modelContainer.mainContext.insert(SDTag.t3)
        modelContainer.mainContext.insert(SDTag.t4)
        modelContainer.mainContext.insert(SDTag.t5)
        modelContainer.mainContext.insert(SDTag.t6)
        modelContainer.mainContext.insert(SDTag.t7)
        modelContainer.mainContext.insert(SDTag.t8)
        modelContainer.mainContext.insert(SDTag.t9)
        modelContainer.mainContext.insert(SDTag.t10)
        modelContainer.mainContext.insert(SDTag.t11)

        modelContainer.mainContext.insert(SDGroup.g1)
        modelContainer.mainContext.insert(SDGroup.g2)
        modelContainer.mainContext.insert(SDGroup.g3)
        modelContainer.mainContext.insert(SDGroup.g4)
        modelContainer.mainContext.insert(SDGroup.g5)
        modelContainer.mainContext.insert(SDGroup.g6)

        modelContainer.mainContext.insert(SDPlace.l1)
        modelContainer.mainContext.insert(SDPlace.l2)
        modelContainer.mainContext.insert(SDPlace.l3)
        modelContainer.mainContext.insert(SDPlace.l4)
        modelContainer.mainContext.insert(SDPlace.l5)
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

// Constants
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
    struct userDefaultsKeys {
    }
}
