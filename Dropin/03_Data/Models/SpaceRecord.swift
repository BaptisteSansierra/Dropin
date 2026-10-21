//
//  SpaceRecord.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/26.
//

import Foundation
import SwiftData

@Model
final class SpaceRecord {
    var identifier: UUID
    var name: String
    var color: String  // hexadecimal value
    var icon: Icon
    var ownerId: UUID
    // Dates
    var createdAt: Date     // Set at creation
    var updatedAt: Date     // Set on every mutation; drives dirty detection
    var syncedAt: Date?     // Set on successful push; nil = never synced
    var deletedAt: Date?    // Soft delete

    init(identifier: UUID, name: String, color: String, icon: Icon, ownerId: UUID) {
        self.identifier = identifier
        self.name = name
        self.color = color
        self.icon = icon
        self.ownerId = ownerId
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.syncedAt = nil
        self.deletedAt = nil
    }
}
