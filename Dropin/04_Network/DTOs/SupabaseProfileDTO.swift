//
//  SupabaseProfileDTO.swift
//  Dropin
//

import Foundation

struct SupabaseProfileDTO: Codable {
    let id: UUID
    let email: String?
    let displayName: String?
    let plan: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case plan        = "plan"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }

    /// Explicit encode so nullable columns (`email`, `display_name`) are sent
    /// as JSON `null` rather than being omitted. See SupabasePlaceDTO for the
    /// same rationale (Postgrest upsert preserves columns missing from the payload).
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,          forKey: .id)
        try c.encode(email,       forKey: .email)
        try c.encode(displayName, forKey: .displayName)
        try c.encode(plan,        forKey: .plan)
        try c.encode(createdAt,   forKey: .createdAt)
        try c.encode(updatedAt,   forKey: .updatedAt)
    }

    init(from profile: ProfileEntity) {
        self.id          = profile.id
        self.email       = profile.email
        self.displayName = profile.displayName
        self.plan        = profile.plan.rawValue
        self.createdAt   = profile.createdAt
        self.updatedAt   = profile.updatedAt
    }

    func toDomain() -> ProfileEntity {
        ProfileEntity(id: id,
                      email: email,
                      displayName: displayName,
                      plan: UserPlan(rawValue: plan) ?? .free,
                      createdAt: createdAt,
                      updatedAt: updatedAt)
    }
}
