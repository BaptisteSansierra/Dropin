//
//  SupabaseImageDTO.swift
//  Dropin
//

import Foundation

struct SupabaseImageDTO: Codable {
    let id: UUID
    let userId: UUID
    let placeId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case placeId   = "place_id"
        case createdAt = "created_at"
    }
}
