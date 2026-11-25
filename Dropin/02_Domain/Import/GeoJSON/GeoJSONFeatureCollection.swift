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
        do {
            return try JSONDecoder().decode(Self.self, from: data)
        } catch {
            var msg = error.localizedDescription
            if let decodingError = error as? DecodingError {
                switch decodingError {
                    case .keyNotFound(let key, let context):
                        msg = "Missing key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: ".")) — \(context.debugDescription)"
                    case .typeMismatch(let type, let context):
                        msg = "Type mismatch for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
                    case .valueNotFound(let type, let context):
                        msg = "Null value for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
                    case .dataCorrupted(let context):
                        msg = "Corrupted data at \(context.codingPath.map(\.stringValue).joined(separator: ".")): \(context.debugDescription)"
                    @unknown default:
                        msg = "\(decodingError)"
                }
            }
            Log.warning("Decoding error: \(msg)")
            throw ImportError.decoding(msg)
        }
    }
}
