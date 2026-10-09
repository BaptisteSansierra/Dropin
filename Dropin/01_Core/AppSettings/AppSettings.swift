//
//  AppSettings.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/04/26.
//

import Foundation
//import MapKit
 
@MainActor
@Observable class AppSettings {
    
    var mapSettings: MapSettings { didSet { store() } }

    init() {
        let store = UserDefaults.standard
        let keys = DropinApp.userDefaultsKeys.self

        var pinStyle: PinStyle = .rounded
        if store.object(forKey: keys.pinStyle) != nil {
            pinStyle = PinStyle(rawValue: store.integer(forKey: keys.pinStyle)) ?? .rounded
        }
        var pinSize: Double = 36
        if store.object(forKey: keys.pinSize) != nil {
            pinSize = store.double(forKey: keys.pinSize).clamped(to: MapSettings.pinSizeRange)
        }
        
        var mapType = MapSettings.MapType.standard
        if let stored = store.object(forKey: keys.mapType) as? Int {
            if let mt = MapSettings.MapType(rawValue: stored) {
                mapType = mt
            }
        }
        
        var poiConfig = [POIBundle.transport,
                         POIBundle.nature]
        if let arr = store.object(forKey: keys.poiConfig) as? [Int] {
            poiConfig = arr
                .filter({ POIBundle(rawValue: $0) != nil })
                .map({ POIBundle(rawValue: $0)! })
        }
                
        var clustering = false
        if store.object(forKey: keys.clustering) != nil {
            clustering = store.bool(forKey: keys.clustering)
        }

        mapSettings = MapSettings(pinStyle: pinStyle,
                                  pinSize: pinSize,
                                  mapType: mapType,
                                  poiConfig: Set(poiConfig),
                                  clustering: clustering)
    }
    
    func equals(_ other: AppSettings) -> Bool {
        mapSettings.pinStyle == other.mapSettings.pinStyle &&
        mapSettings.pinSize == other.mapSettings.pinSize &&
        mapSettings.mapType == other.mapSettings.mapType &&
        mapSettings.poiConfig == other.mapSettings.poiConfig &&
        mapSettings.clustering == other.mapSettings.clustering
    }
    
    private func store() {
        let store = UserDefaults.standard
        let pinStyleKey = DropinApp.userDefaultsKeys.pinStyle
        let pinSizeKey = DropinApp.userDefaultsKeys.pinSize
        let mapTypeKey = DropinApp.userDefaultsKeys.mapType
        let poiConfigKey = DropinApp.userDefaultsKeys.poiConfig
        let clusteringKey = DropinApp.userDefaultsKeys.clustering
        store.set(mapSettings.pinStyle.rawValue, forKey: pinStyleKey)
        store.set(mapSettings.pinSize, forKey: pinSizeKey)
        store.set(mapSettings.mapType.rawValue, forKey: mapTypeKey)
        store.set(mapSettings.poiConfig.map { $0.rawValue }, forKey: poiConfigKey)
        store.set(mapSettings.clustering, forKey: clusteringKey)
    }
}
