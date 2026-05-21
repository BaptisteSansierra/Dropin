//
//  SDProfile.swift
//  Dropin
//

import Foundation
import SwiftData

@Model
final class SDProfile {
    var identifier: UUID
    var email: String?
    var displayName: String?
    var plan: String         // UserPlan.rawValue (e.g. "free", "early_stage")
    // Dates
    var createdAt: Date      // Set at creation
    var updatedAt: Date      // Bumped on every mutation; drives dirty detection
    var syncedAt: Date?      // Set on successful push; nil = never synced

    init(identifier: UUID,
         email: String?,
         displayName: String?,
         plan: String,
         createdAt: Date,
         updatedAt: Date) {
        self.identifier = identifier
        self.email = email
        self.displayName = displayName
        self.plan = plan
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncedAt = nil
    }
}
