//
//  TagEntity+Extension.swift
//  DropinTests
//
//  Created by baptiste sansierra on 16/10/25.
//

import Foundation
@testable import Dropin

extension TagEntity {  // Mock extension
    static func mockTags() -> [TagEntity] {
        let t1 = TagEntity(name: "Clean restrooms", color: "9944AA")
        let t2 = TagEntity(name: "Ugly restrooms", color: "3388CC")
        let t3 = TagEntity(name: "Pizza", color: "997766")
        let t4 = TagEntity(name: "Burger", color: "7744AA")
        let t5 = TagEntity(name: "Salad", color: "7744AA")
        let t6 = TagEntity(name: "Nature", color: "FF4433")
        let t7 = TagEntity(name: "Kidz friendly", color: "FF4433")
        let t8 = TagEntity(name: "Bad food", color: "AA8855")
        let t9 = TagEntity(name: "5 ⭐️ ", color: "AA5588")
        let t10 = TagEntity(name: "Healthy", color: "AA44FF")
        let t11 = TagEntity(name: "Pasta", color: "AAFF99")
        let t12 = TagEntity(name: "Rock", color: "000000")
        let t13 = TagEntity(name: "Cool", color: "449966")
        let t14 = TagEntity(name: "Take away", color: "0054F8")
        let t15 = TagEntity(name: "Lavomatic", color: "50A348")
        let t16 = TagEntity(name: "Eco", color: "9045A3")
        return [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16]
    }
}
