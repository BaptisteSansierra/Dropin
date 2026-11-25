//
//  strings.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/11/26.
//

import Foundation
import MapKit

///
/// Dropin constants
///
extension DropinApp {
    struct strings {
        static let app = "Dropin"
        static let contact = "contact@dropin.lat"
        static let developer = "Baptiste Sansierra"
        static let exportExtension = "dropin"      // TODO: use AppConfig.scheme instead ? will that break test targets ?
        static let geojsonExtension = "geojson"
        static let jsonExtension = "json"
        static let exportUTTypeId = "com.dropin.export"
    }
    struct urls {
        // redirectTo/emailRedirectTo targets for Supabase auth emails.
        // Web pages for now; will move to the dropin:// scheme (registered in
        // Info.plist's CFBundleURLTypes) once in-app handling is implemented.
        // Opened in the app as Universal Links when it's installed (AuthLink, applinks:dropin.lat)
        static let resetPasswordURL = URL(string: "https://dropin.lat/reset-password.html")!
        static let emailConfirmedURL = URL(string: "https://dropin.lat/email-confirmed.html")!
        // Mapstr export/import instructions
        static let importMapstrDesc = URL(string: "https://dropin.lat/import-mapstr")!
        // Google export/import instructions
        static let importGooleDesc = URL(string: "https://dropin.lat/import-googleMaps")!
        // base shared url
        static let shareBaseURL = URL(string: "https://dropin.lat/p.html")!
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
        //static let hardStartRegion: MKCoordinateRegion? = nil
        static let hardStartRegion: MKCoordinateRegion? = {
            #if DEBUG
            // "lat,lon,latDelta,lonDelta"
            guard let value = ProcessInfo.processInfo.environment["HARD_START_REGION"] else { return nil }
            let v = value.split(separator: ",").compactMap { Double($0) }
            guard v.count == 4 else { return nil }
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: v[0], longitude: v[1]),
                                      span: MKCoordinateSpan(latitudeDelta: v[2], longitudeDelta: v[3]))
            #else
            return nil
            #endif
        }()
        
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
        static let passwordRecoveryPending = "service.auth.recovery_pending"
    }
}
