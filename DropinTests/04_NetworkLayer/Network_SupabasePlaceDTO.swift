//
//  Network_SupabasePlaceDTO.swift
//  DropinTests
//

import Testing
import Foundation
import CoreLocation
@testable import Dropin

struct Network_SupabasePlaceDTO {

    private func makePlace(applePlaceID: String? = "abc123",
                           appleNotFoundAt: Date? = Date(timeIntervalSince1970: 1_700_000_000)) -> Place {
        Place(id: UUID(),
             name: "Test Place",
             coordinates: .barcelona,
             address: nil,
             address2: nil,
             tags: [],
             category: nil,
             images: [],
             icon: nil,
             rating: nil,
             phone: [],
             email: [],
             url: [],
             notes: nil,
             applePlaceID: applePlaceID,
             appleNotFoundAt: appleNotFoundAt,
             createdAt: Date(timeIntervalSince1970: 1_700_000_000),
             updatedAt: Date(timeIntervalSince1970: 1_700_000_100),
             deletedAt: nil,
             spaceId: UUID())
    }

    @Test func toDomainPreservesAppleFields() {
        let original = makePlace()
        let dto = SupabasePlaceDTO(from: original, userId: UUID())
        let back = dto.toDomain()
        #expect(back.applePlaceID == original.applePlaceID)
        #expect(back.appleNotFoundAt == original.appleNotFoundAt)
    }

    @Test func toDomainPreservesNilAppleFields() {
        let original = makePlace(applePlaceID: nil, appleNotFoundAt: nil)
        let dto = SupabasePlaceDTO(from: original, userId: UUID())
        let back = dto.toDomain()
        #expect(back.applePlaceID == nil)
        #expect(back.appleNotFoundAt == nil)
    }

    @Test func encodesUnderSnakeCaseKeys() throws {
        let dto = SupabasePlaceDTO(from: makePlace(), userId: UUID())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["apple_place_id"] != nil)
        #expect(json?["apple_not_found_at"] != nil)
    }

    // Explicit `encode` (not `encodeIfPresent`) must still write a JSON `null`
    // for nil Apple fields, so clearing them server-side actually nulls the column.
    @Test func encodesNullForNilAppleFields() throws {
        let dto = SupabasePlaceDTO(from: makePlace(applePlaceID: nil, appleNotFoundAt: nil), userId: UUID())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?.keys.contains("apple_place_id") == true)
        #expect(json?["apple_place_id"] is NSNull)
        #expect(json?.keys.contains("apple_not_found_at") == true)
        #expect(json?["apple_not_found_at"] is NSNull)
    }

    @Test func jsonRoundTripPreservesAppleFields() throws {
        let original = makePlace()
        let dto = SupabasePlaceDTO(from: original, userId: UUID())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(dto)
        let decoded = try decoder.decode(SupabasePlaceDTO.self, from: data)
        #expect(decoded.applePlaceID == original.applePlaceID)
        #expect(decoded.appleNotFoundAt == original.appleNotFoundAt)
    }
}
