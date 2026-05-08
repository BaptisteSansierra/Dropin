//
//  SDImage.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import Foundation
import SwiftData

@Model
final class SDImage {
    var id: UUID
    @Attribute(.externalStorage) var thumbnail: Data
    @Attribute(.externalStorage) var full: Data
    var place: SDPlace?
    // Dates
    var createdAt: Date     // Set at creation
    var syncedAt: Date?     // Set on successful push; nil = never synced
    var deletedAt: Date?    // Soft delete

    init(id: UUID = UUID(), thumbnail: Data, full: Data) {
        self.id = id
        self.thumbnail = thumbnail
        self.full = full
        self.createdAt = Date()
        self.syncedAt = nil
        self.deletedAt = nil
    }
}
