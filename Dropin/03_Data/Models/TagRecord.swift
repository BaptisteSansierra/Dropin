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
    // Import source
    var importedAt: Date? = nil
    var importSrc: String? = nil
    // Storage partition: always real once persisted. See TagRepositoryImpl.
    var spaceId: UUID

    init(identifier: UUID, spaceId: UUID, name: String, color: String, places: [PlaceRecord] = []) {
        self.identifier = identifier
        self.spaceId = spaceId
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
    
    static func mockTags(spaceId: UUID) -> [TagRecord] {
        let t1 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Clean restrooms", color: "9944AA")
        let t2 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Ugly restrooms", color: "3388CC")
        let t3 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Pizza", color: "997766")
        let t4 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Burger", color: "7744AA")
        let t5 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Salad", color: "7744AA")
        let t6 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Nature", color: "FF4433")
        let t7 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Kidz friendly", color: "FF4433")
        let t8 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Bad food", color: "AA8855")
        let t9 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "5 ⭐️ ", color: "AA5588")
        let t10 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Healthy", color: "AA44FF")
        let t11 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Pasta", color: "AAFF99")
        let t12 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Rock", color: "000000")
        let t13 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Cool", color: "449966")
        let t14 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Take away", color: "0054F8")
        let t15 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Lavomatic", color: "50A348")
        let t16 = TagRecord(identifier: UUID(), spaceId: spaceId, name: "Eco", color: "9045A3")
        return [t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16]
    }
}

#endif
