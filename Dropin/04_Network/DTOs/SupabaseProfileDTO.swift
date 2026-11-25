//
//  SupabaseProfileDTO.swift
//  Dropin
//

import Foundation

/// Read-only: profile writes go through RemoteProfileRepository.updateDisplayName (display_name only).
struct SupabaseProfileDTO: Decodable {
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

    func toDomain() -> Profile {
        Profile(id: id,
                      email: email,
                      displayName: displayName,
                      plan: UserPlan(rawValue: plan) ?? .free,
                      createdAt: createdAt,
                      updatedAt: updatedAt)
    }
}
