//
//  GeoJSONFeature.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/11/26.
//

import Foundation

struct GeoJSONFeature<Properties: Decodable>: Decodable {
    let geometry: GeoJSONGeometry
    let properties: Properties
}
