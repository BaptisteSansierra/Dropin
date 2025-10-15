//
//  SDTag.swift
//  Dropin
//
//  Created by baptiste sansierra on 22/7/25.
//

import Foundation
import SwiftData

@Model
final class SDTag {
    var identifier: String
    var name: String
    var color: String  // hexadecimal value
    var places: [SDPlace]?
    var creationDate: Date
    
    init(identifier: String, name: String, color: String, places: [SDPlace]? = nil, creationDate: Date) {
        self.identifier = identifier
        self.name = name
        self.color = color
        self.places = places
        self.creationDate = creationDate
    }
}

#if DEBUG

extension SDTag {  // Mock extension
    
    static func mockTags() -> [SDTag] {
        let t1 = SDTag(identifier: UUID().uuidString, name: "Clean restrooms", color: "9944AA", creationDate: Date())
        let t2 = SDTag(identifier: UUID().uuidString, name: "Ugly restrooms", color: "3388CC", creationDate: Date())
        let t3 = SDTag(identifier: UUID().uuidString, name: "Pizza", color: "997766", creationDate: Date())
        let t4 = SDTag(identifier: UUID().uuidString, name: "Burger", color: "7744AA", creationDate: Date())
        let t5 = SDTag(identifier: UUID().uuidString, name: "Salad", color: "7744AA", creationDate: Date())
        let t6 = SDTag(identifier: UUID().uuidString, name: "Nature", color: "FF4433", creationDate: Date())
        let t7 = SDTag(identifier: UUID().uuidString, name: "Kidz friendly", color: "FF4433", creationDate: Date())
        let t8 = SDTag(identifier: UUID().uuidString, name: "Bad food", color: "AA8855", creationDate: Date())
        let t9 = SDTag(identifier: UUID().uuidString, name: "5 ⭐️ ", color: "AA5588", creationDate: Date())
        let t10 = SDTag(identifier: UUID().uuidString, name: "Healthy", color: "AA44FF", creationDate: Date())
        let t11 = SDTag(identifier: UUID().uuidString, name: "Pasta", color: "AAFF99", creationDate: Date())
        let t12 = SDTag(identifier: UUID().uuidString, name: "Rock", color: "000000", creationDate: Date())
        let t13 = SDTag(identifier: UUID().uuidString, name: "Cool", color: "449966", creationDate: Date())
        let t14 = SDTag(identifier: UUID().uuidString, name: "Take away", color: "0054F8", creationDate: Date())
        let t15 = SDTag(identifier: UUID().uuidString, name: "Lavomatic", color: "50A348", creationDate: Date())
        let t16 = SDTag(identifier: UUID().uuidString, name: "Eco", color: "9045A3", creationDate: Date())
        return [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16]
    }
}
#endif
