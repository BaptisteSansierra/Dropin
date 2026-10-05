//
//  PinStyle.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/10/26.
//

import Foundation

enum PinStyle: Int, CaseIterable, Identifiable {
    case rounded = 0
    case rect = 1
    
    var id: Int { rawValue }
    var displayName: String {
        switch self {
            case .rounded:
                return String(localized: LocalizedStringResource(stringLiteral: "common.form.rounded"))
            case .rect:
                return String(localized: LocalizedStringResource(stringLiteral: "common.form.squared"))
        }
    }
}
