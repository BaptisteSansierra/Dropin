//
//  AppSettings.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/04/26.
//

import Foundation

enum PinStyle: Int, CaseIterable, Identifiable {
    case rounded = 0
    case rect = 1
    
    var id: Int { rawValue }
    var displayName: String {
        switch self {
            case .rounded:
                return String(localized: LocalizedStringResource(stringLiteral: "common.form.rounded"))
            case .rect:
                return String(localized: LocalizedStringResource(stringLiteral: "common.form.squared"))
        }
    }
}

struct MapSettings: Equatable {
    var pinStyle: PinStyle
    var pinSize: Double
    /// `hidePOI` show/hide the Points Of Interest in the main map
    var hidePOI: Bool
    /// `satellite` enable/disable the satellite view in the main map
    var satellite: Bool
    var clustering: Bool

    static let pinSizeRange: ClosedRange<Double> = 25...55
    
    func isDiffAffectsAnnotations(_ other: MapSettings) -> Bool {
        return pinStyle != other.pinStyle ||
               pinSize != other.pinSize ||
               clustering != other.clustering
    }
}

@MainActor
@Observable class AppSettings {
    
//    var pinStyle: PinStyle { didSet { store() } }
//    var pinSize: Double { didSet { store() } }
//    /// `hidePOI` show/hide the Points Of Interest in the main map
//    var hidePOI: Bool { didSet { store() } }
//    /// `satellite` enable/disable the satellite view in the main map
//    var satellite: Bool { didSet { store() } }
//
//    var clustering: Bool { didSet { store() } }
//
//    static let pinSizeRange: ClosedRange<Double> = 25...55

    var mapSettings: MapSettings { didSet { store() } }

    init() {
        let store = UserDefaults.standard
        let pinStyleKey = DropinApp.userDefaultsKeys.pinStyle
        let pinSizeKey = DropinApp.userDefaultsKeys.pinSize
        let hidePOIKey = DropinApp.userDefaultsKeys.hidePOI
        let satelliteKey = DropinApp.userDefaultsKeys.satellite
        let clusteringKey = DropinApp.userDefaultsKeys.clustering
        mapSettings = MapSettings(pinStyle: .rounded,
                                  pinSize: 36,
                                  hidePOI: true,
                                  satellite: false,
                                  clustering: true)
        if let _ = store.object(forKey: pinStyleKey) {
            mapSettings.pinStyle = PinStyle(rawValue: store.integer(forKey: pinStyleKey)) ?? .rounded
        }
        if let _ = store.object(forKey: pinSizeKey) {
            mapSettings.pinSize = store.double(forKey: pinSizeKey).clamped(to: MapSettings.pinSizeRange)
        }
        if let _ = store.object(forKey: hidePOIKey) {
            mapSettings.hidePOI = store.bool(forKey: hidePOIKey)
        }
        if let _ = store.object(forKey: satelliteKey) {
            mapSettings.satellite = store.bool(forKey: satelliteKey)
        }
        if let _ = store.object(forKey: clusteringKey) {
            mapSettings.clustering = store.bool(forKey: clusteringKey)
        }
    }
    
    func equals(_ other: AppSettings) -> Bool {
        mapSettings.pinStyle == other.mapSettings.pinStyle &&
        mapSettings.pinSize == other.mapSettings.pinSize &&
        mapSettings.hidePOI == other.mapSettings.hidePOI &&
        mapSettings.satellite == other.mapSettings.satellite &&
        mapSettings.clustering == other.mapSettings.clustering
    }
    
    private func store() {
        let store = UserDefaults.standard
        let pinStyleKey = DropinApp.userDefaultsKeys.pinStyle
        let pinSizeKey = DropinApp.userDefaultsKeys.pinSize
        let hidePOIKey = DropinApp.userDefaultsKeys.hidePOI
        let satelliteKey = DropinApp.userDefaultsKeys.satellite
        let clusteringKey = DropinApp.userDefaultsKeys.clustering
        store.set(mapSettings.pinStyle.rawValue, forKey: pinStyleKey)
        store.set(mapSettings.pinSize, forKey: pinSizeKey)
        store.set(mapSettings.hidePOI, forKey: hidePOIKey)
        store.set(mapSettings.satellite, forKey: satelliteKey)
        store.set(mapSettings.clustering, forKey: clusteringKey)
    }
}
