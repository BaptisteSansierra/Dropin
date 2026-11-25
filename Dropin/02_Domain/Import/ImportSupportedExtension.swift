//
//  ImportSupportedExtension.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/11/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum ImportSupportedExtension: String, Codable, CustomStringConvertible, CaseIterable {
    case dropin
    case geojson
    case json

    var description: String {
        switch self {
            case .dropin: DropinApp.strings.exportExtension
            case .geojson: DropinApp.strings.geojsonExtension
            case .json: DropinApp.strings.jsonExtension
        }
    }

    var displayName: LocalizedStringKey {
        switch self {
            case .dropin: "file_format.dropin.beautified"
            case .geojson: "file_format.geojson.beautified"
            case .json: "file_format.json.beautified"
        }
    }

    var matchingSource: [ImportSource] {
        switch self {
            case .dropin: [.dropin]
            case .geojson: [.mapstr, .google, .unknown]
            case .json: [.google, .unknown]
        }
    }
    
    var uttType: UTType? {
        switch self {
            case .dropin:
                guard let dropinType = UTType(DropinApp.strings.exportUTTypeId) else {
                    assertionFailure("unknown dropin file type")
                    return nil
                }
                return dropinType
            case .geojson:
                return .geoJSON
            case .json:
                return .json
        }
    }
}
