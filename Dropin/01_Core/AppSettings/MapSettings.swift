//
//  MapSettings.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/10/26.
//

import Foundation
import MapKit

struct MapSettings: Equatable {

    // MARK: enums
    enum MapType: Int {
        case standard
        case satellite
        case hybrid

        var displayName: String {
            switch self {
                case .standard:
                    return String(localized: LocalizedStringResource(stringLiteral: "common.map_type.standard"))
                case .satellite:
                    // Note: satellite not used in the app at the moment
                    return String(localized: LocalizedStringResource(stringLiteral: "common.map_type.satellite"))
                case .hybrid:
                    // Note: takes satellite name
                    return String(localized: LocalizedStringResource(stringLiteral: "common.map_type.satellite"))
            }
        }
    }

    // MARK: static properties
    static let pinSizeRange: ClosedRange<Double> = 25...55

    // MARK: properties
    var pinStyle: PinStyle
    var pinSize: Double
    var mapType: MapType
    var poiConfig: Set<POIBundle>
    var clustering: Bool

    // MARK: public methods
    func diffAffectsAnnotations(_ other: MapSettings) -> Bool {
        return pinStyle != other.pinStyle ||
               pinSize != other.pinSize ||
               clustering != other.clustering
    }
    
    func diffAffectsMapConfig(_ config: MKMapConfiguration) -> Bool {
        if config.mapType != mapType {
            return false
        }
        // POI filter only exists on standard/hybrid configurations
        guard mapType != .satellite else { return true }

        let pois = Array(POIBundle.list(for: Set(poiConfig)))
        let newFilter = MKPointOfInterestFilter(including: pois)

        let currentFilter: MKPointOfInterestFilter?
        switch mapType {
            case .standard:
                currentFilter = (config as? MKStandardMapConfiguration)?.pointOfInterestFilter
            case .hybrid:
                currentFilter = (config as? MKHybridMapConfiguration)?.pointOfInterestFilter
            case .satellite:
                return true
        }
        return currentFilter == newFilter
    }
    
    func mapConfig() -> MKMapConfiguration {
        let pois = Array(POIBundle.list(for: Set(poiConfig)))
        let poiFilter = MKPointOfInterestFilter(including: pois)

        switch mapType {
            case .standard:
                let config = MKStandardMapConfiguration()
                config.pointOfInterestFilter = poiFilter
                return config
            case .hybrid:
                let config = MKHybridMapConfiguration()
                config.pointOfInterestFilter = poiFilter
                return config
            case .satellite:
                return MKImageryMapConfiguration()
        }
    }
}
