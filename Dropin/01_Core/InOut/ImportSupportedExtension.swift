//
//  ImportSupportedExtension.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/11/26.
//

import Foundation
import SwiftUI

enum ImportSupportedExtension: String, Codable, CustomStringConvertible {
    case dropin
    case geojson
    
    var description: String {
        switch self {
            case .dropin: DropinApp.strings.exportExtension
            case .geojson: DropinApp.strings.geojsonExtension
        }
    }

    var displayName: LocalizedStringKey {
        switch self {
            case .dropin: "file_format.dropin.beautified"
            case .geojson: "file_format.geojson.beautified"
        }
    }

    var matchingSource: [ImportSource] {
        switch self {
            case .dropin: [.dropin]
            case .geojson: [.mapstr, .unknown]
        }
    }
}
