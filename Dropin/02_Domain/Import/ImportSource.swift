//
//  ImportSource.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation
import SwiftUI

enum ImportSource: String, Codable, CustomStringConvertible {
    case dropin
    case mapstr
    case google
    case unknown
    
    var description: String {
        switch self {
            case .dropin: "Dropin"
            case .mapstr: "Mapstr"
            case .google: "Google"
            case .unknown: "Unknown"
        }
    }
    
    var displayName: LocalizedStringKey {
        switch self {
            case .dropin: "import_source.dropin"
            case .mapstr: "import_source.mapstr"
            case .google: "import_source.google"
            case .unknown: "import_source.other"
        }
    }

    var matchingExtensions: [ImportSupportedExtension] {
        var extensions: [ImportSupportedExtension] = []
        for ext in ImportSupportedExtension.allCases {
            if ext.matchingSource.contains(self) {
                extensions.append(ext)
            }
        }
        return extensions
    }
}
