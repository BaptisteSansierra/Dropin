//
//  MKMapConfiguration+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/26.
//

import MapKit

extension MKMapConfiguration {

    var mapType: MapSettings.MapType {
        switch self {
            case is MKStandardMapConfiguration: return MapSettings.MapType.standard
            case is MKHybridMapConfiguration: return MapSettings.MapType.hybrid
            case is MKImageryMapConfiguration: return MapSettings.MapType.satellite
            default: return MapSettings.MapType.standard
        }
    }
}
