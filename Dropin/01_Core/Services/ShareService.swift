//
//  ShareService.swift
//  Dropin
//

import Foundation
import Supabase

protocol ShareServiceProtocol: Sendable {
    /// Returns the public share URL for a place (Dropin_frontend's p.html?id=<share_id>),
    /// reusing an existing active share if one already exists so repeat taps don't spam
    /// new rows. RLS scopes `shares` to the signed-in user (see
    /// Dropin_backend/supabase/migrations/20260925000001_shares.sql).
    func shareURL(placeId: UUID) async throws -> URL
}

final class ShareService: ShareServiceProtocol {

    /// Mirrors Dropin_frontend's live domain (see its CLAUDE.md) — not derived from
    /// SupabaseConfig, which points at the backend project, not the static site.
    private static let baseURL = URL(string: "https://dropin.lat/p.html")!

    private let client: SupabaseClient
    private let auth: any AuthServiceProtocol

    init(client: SupabaseClient, auth: any AuthServiceProtocol) {
        self.client = client
        self.auth = auth
    }

    func shareURL(placeId: UUID) async throws -> URL {
        let userId = try await requireUserId()
        let shareId: UUID
        if let existing = try await existingActiveShareId(placeId: placeId, userId: userId) {
            shareId = existing
        } else {
            shareId = try await createShare(placeId: placeId, userId: userId)
        }
        return Self.url(for: shareId)
    }

    // MARK: - private

    private struct ShareRow: Decodable {
        let id: UUID
    }

    private func existingActiveShareId(placeId: UUID, userId: UUID) async throws -> UUID? {
        let rows: [ShareRow] = try await client
            .from("shares")
            .select("id")
            .eq("place_id", value: placeId)
            .eq("user_id", value: userId)
            .is("revoked_at", value: nil)
            .limit(1)
            .execute()
            .value
        return rows.first?.id
    }

    private struct NewShare: Encodable {
        let id: UUID
        let userId: UUID
        let placeId: UUID

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case placeId = "place_id"
        }
    }

    private func createShare(placeId: UUID, userId: UUID) async throws -> UUID {
        let shareId = UUID()
        try await client
            .from("shares")
            .insert(NewShare(id: shareId, userId: userId, placeId: placeId))
            .execute()
        return shareId
    }

    private static func url(for shareId: UUID) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "id", value: shareId.uuidString)]
        return components.url!
    }

    @MainActor
    private func requireUserId() throws -> UUID {
        guard let session = auth.session else { throw AuthServiceError.notAuthenticated }
        return session.userId
    }
}
