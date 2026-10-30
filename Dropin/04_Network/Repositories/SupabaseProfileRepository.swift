//
//  SupabaseProfileRepository.swift
//  Dropin

import Supabase
import Foundation

final class SupabaseProfileRepository: RemoteProfileRepository {
    private let client: SupabaseClient
    private let auth: any AuthServiceProtocol

    /// Immutable after init; `.string(from:)` is documented thread-safe by Apple.
    nonisolated(unsafe) private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    init(client: SupabaseClient, auth: any AuthServiceProtocol) {
        self.client = client
        self.auth = auth
    }

    func fetch() async throws -> Profile? {
        let userId = try await requireUserId()
        let dtos: [SupabaseProfileDTO] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value
        return dtos.first?.toDomain()
    }

    func fetch(updatedAfter date: Date) async throws -> Profile? {
        let userId = try await requireUserId()
        let dateStr = Self.dateFormatter.string(from: date)
        let dtos: [SupabaseProfileDTO] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .gt("updated_at", value: dateStr)
            .limit(1)
            .execute()
            .value
        return dtos.first?.toDomain()
    }

    /// display_name is the only column `authenticated` may write (cf. migration 20261029000002_profiles_lock_plan).
    /// Every other column is server-owned and comes back through the profile pull.
    func updateDisplayName(_ profile: Profile) async throws {
        _ = try await requireUserId()
        try await client.from("profiles")
            .update(["display_name": profile.displayName])
            .eq("id", value: profile.id)
            .execute()
    }

    @MainActor
    private func requireUserId() throws -> UUID {
        guard let session = auth.session else { throw AuthServiceError.notAuthenticated }
        return session.userId
    }
}
