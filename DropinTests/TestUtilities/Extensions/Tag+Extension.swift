//
//  Tag+Extension.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
@testable import Dropin

extension Dropin.Tag {  // Mock extension
    static func mockTags() -> [Dropin.Tag] {
        let t1 = Dropin.Tag(name: "Clean restrooms", color: "9944AA")
        let t2 = Dropin.Tag(name: "Ugly restrooms", color: "3388CC")
        let t3 = Dropin.Tag(name: "Pizza", color: "997766")
        let t4 = Dropin.Tag(name: "Burger", color: "7744AA")
        let t5 = Dropin.Tag(name: "Salad", color: "7744AA")
        let t6 = Dropin.Tag(name: "Nature", color: "FF4433")
        let t7 = Dropin.Tag(name: "Kidz friendly", color: "FF4433")
        let t8 = Dropin.Tag(name: "Bad food", color: "AA8855")
        let t9 = Dropin.Tag(name: "5 ⭐️ ", color: "AA5588")
        let t10 = Dropin.Tag(name: "Healthy", color: "AA44FF")
        let t11 = Dropin.Tag(name: "Pasta", color: "AAFF99")
        let t12 = Dropin.Tag(name: "Rock", color: "000000")
        let t13 = Dropin.Tag(name: "Cool", color: "449966")
        let t14 = Dropin.Tag(name: "Take away", color: "0054F8")
        let t15 = Dropin.Tag(name: "Lavomatic", color: "50A348")
        let t16 = Dropin.Tag(name: "Eco", color: "9045A3")
        return [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16]
    }
}
