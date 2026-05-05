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

@MainActor
@Observable class AppSettings {
    var pinStyle: PinStyle { didSet { store() } }
    var pinSize: Double { didSet { store() } }
    /// `hidePOI` show/hide the Points Of Interest in the main map
    var hidePOI: Bool { didSet { store() } }
    /// `satellite` enable/disable the satellite view in the main map
    var satellite: Bool { didSet { store() } }

    static let pinSizeRange: ClosedRange<Double> = 25...55

    init() {
        let store = UserDefaults.standard
        let pinStyleKey = DropinApp.userDefaultsKeys.pinStyle
        let pinSizeKey = DropinApp.userDefaultsKeys.pinSize
        let hidePOIKey = DropinApp.userDefaultsKeys.hidePOI
        let satelliteKey = DropinApp.userDefaultsKeys.satellite
        pinStyle = .rounded
        if let _ = store.object(forKey: pinStyleKey) {
            pinStyle = PinStyle(rawValue: store.integer(forKey: pinStyleKey)) ?? .rounded
        }
        pinSize = 36
        if let _ = store.object(forKey: pinSizeKey) {
            pinSize = store.double(forKey: pinSizeKey).clamped(to: AppSettings.pinSizeRange)
        }
        hidePOI = true
        if let _ = store.object(forKey: hidePOIKey) {
            hidePOI = store.bool(forKey: hidePOIKey)
        }
        satellite = false
        if let _ = store.object(forKey: satelliteKey) {
            satellite = store.bool(forKey: satelliteKey)
        }
    }
    
    private func store() {
        let store = UserDefaults.standard
        let pinStyleKey = DropinApp.userDefaultsKeys.pinStyle
        let pinSizeKey = DropinApp.userDefaultsKeys.pinSize
        let hidePOIKey = DropinApp.userDefaultsKeys.hidePOI
        let satelliteKey = DropinApp.userDefaultsKeys.satellite
        store.set(pinStyle.rawValue, forKey: pinStyleKey)
        store.set(pinSize, forKey: pinSizeKey)
        store.set(hidePOI, forKey: hidePOIKey)
        store.set(satellite, forKey: satelliteKey)
    }
}
