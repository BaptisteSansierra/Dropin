//
//  GeoJSONFeatureCollection.swift
//  Dropin
//
//  Created by baptiste sansierra on 23/11/26.
//

import Foundation

struct GeoJSONFeatureCollection<Properties: Decodable>: Decodable {
    let features: [GeoJSONFeature<Properties>]
}

extension GeoJSONFeatureCollection {
    static func decode(_ data: Data) throws -> Self {
        //do {
            return try! JSONDecoder().decode(Self.self, from: data)
        //} catch {
        //    throw ImportError.corrupted(error.localizedDescription)
        //}
    }
}
