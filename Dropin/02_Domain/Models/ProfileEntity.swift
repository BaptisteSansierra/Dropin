//
//  ProfileEntity.swift
//  Dropin
//

import Foundation

struct ProfileEntity: Hashable, Sendable {
    let id: UUID
    let email: String?
    let displayName: String?
    let plan: UserPlan
    let createdAt: Date
    let updatedAt: Date

    init(id: UUID,
         email: String?,
         displayName: String?,
         plan: UserPlan,
         createdAt: Date,
         updatedAt: Date) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.plan = plan
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Returns a copy with `displayName` replaced and `updatedAt` bumped to now.
    /// Used by the update flow before persisting locally + queuing the push.
    func withDisplayName(_ newDisplayName: String?) -> ProfileEntity {
        ProfileEntity(id: id,
                      email: email,
                      displayName: newDisplayName,
                      plan: plan,
                      createdAt: createdAt,
                      updatedAt: Date())
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
