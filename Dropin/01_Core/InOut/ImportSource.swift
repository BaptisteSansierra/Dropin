//
//  ImportSource.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

enum ImportSource: CustomStringConvertible {
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
}
