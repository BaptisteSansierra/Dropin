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

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
