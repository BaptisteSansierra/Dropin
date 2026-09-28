//
//  TagRecord.swift
//  Dropin
//
//  Created by baptiste sansierra on 22/7/25.
//

import Foundation
import SwiftData

@Model
final class TagRecord {
    var identifier: UUID
    var name: String
    var color: String  // hexadecimal value
    var places: [PlaceRecord]
    // Dates
    var createdAt: Date     // Set at creation
    var updatedAt: Date     // Set on every mutation; drives dirty detection
    var syncedAt: Date?     // Set on successful push; nil = never synced
    var deletedAt: Date?    // Soft delete
    
    init(identifier: UUID, name: String, color: String, places: [PlaceRecord] = []) {
        self.identifier = identifier
        self.name = name
        self.color = color
        self.places = places
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.syncedAt = nil
        self.deletedAt = nil
    }
}

#if DEBUG

extension TagRecord {  // Mock extension
    
    static func mockTags() -> [TagRecord] {
        let t1 = TagRecord(identifier: UUID(), name: "Clean restrooms", color: "9944AA")
        let t2 = TagRecord(identifier: UUID(), name: "Ugly restrooms", color: "3388CC")
        let t3 = TagRecord(identifier: UUID(), name: "Pizza", color: "997766")
        let t4 = TagRecord(identifier: UUID(), name: "Burger", color: "7744AA")
        let t5 = TagRecord(identifier: UUID(), name: "Salad", color: "7744AA")
        let t6 = TagRecord(identifier: UUID(), name: "Nature", color: "FF4433")
        let t7 = TagRecord(identifier: UUID(), name: "Kidz friendly", color: "FF4433")
        let t8 = TagRecord(identifier: UUID(), name: "Bad food", color: "AA8855")
        let t9 = TagRecord(identifier: UUID(), name: "5 ⭐️ ", color: "AA5588")
        let t10 = TagRecord(identifier: UUID(), name: "Healthy", color: "AA44FF")
        let t11 = TagRecord(identifier: UUID(), name: "Pasta", color: "AAFF99")
        let t12 = TagRecord(identifier: UUID(), name: "Rock", color: "000000")
        let t13 = TagRecord(identifier: UUID(), name: "Cool", color: "449966")
        let t14 = TagRecord(identifier: UUID(), name: "Take away", color: "0054F8")
        let t15 = TagRecord(identifier: UUID(), name: "Lavomatic", color: "50A348")
        let t16 = TagRecord(identifier: UUID(), name: "Eco", color: "9045A3")
        return [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16]
    }
}

#endif
