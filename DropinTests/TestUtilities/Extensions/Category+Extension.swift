//
//  Category+Extension.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
@testable import Dropin

// `Category` alone is ambiguous here against objc/runtime.h's `typedef struct
// objc_category *Category` (visible in this target but not the app target) —
// qualify with the module name / use `Self` throughout this file.
extension Dropin.Category {  // Mock extension
    static func mockCategories() -> [Dropin.Category] {
        let g1 = Self(name: "Restaurant", color: "9944AA", icon: .sf("tag"))
        let g2 = Self(name: "Bar", color: "CC22AA", icon: .sf("tag"))
        let g3 = Self(name: "Trekking", color: "FF9999", icon: .sf("tag"))
        let g4 = Self(name: "Fishing spot", color: "456699", icon: .sf("tag"))
        let g5 = Self(name: "Amusement", color: "DD8855", icon: .sf("tag"))
        let g6 = Self(name: "Disco", color: "7788CC", icon: .sf("tag"))
        let g7 = Self(name: "Culture", color: "2255DD", icon: .sf("tag"))
        let g8 = Self(name: "Shop", color: "FF6600", icon: .sf("tag"))
        let g9 = Self(name: "Body health", color: "4dd333", icon: .sf("tag"))
        let g10 = Self(name: "Laundry", color: "334dd3", icon: .sf("tag"))
        return [g1, g2, g3, g4, g5, g6, g7, g8, g9, g10]
    }
}
