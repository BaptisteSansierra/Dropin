//
//  SupabaseGroupRepository.swift
//  Dropin

import Supabase
import Foundation

final class SupabaseGroupRepository: RemoteGroupRepository {
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

    func upsert(_ group: GroupEntity) async throws {
        let userId = try await requireUserId()
        let dto = SupabaseGroupDTO(from: group, userId: userId)
        try await client.from("groups").upsert(dto, onConflict: "id").execute()
    }

    func fetch(updatedAfter date: Date) async throws -> [GroupEntity] {
        _ = try await requireUserId()
        let dateStr = Self.dateFormatter.string(from: date)
        let dtos: [SupabaseGroupDTO] = try await client
            .from("groups")
            .select()
            .gte("updated_at", value: dateStr)
            .execute()
            .value
        return dtos.map { $0.toDomain() }
    }

    @MainActor
    private func requireUserId() throws -> UUID {
        guard let session = auth.session else { throw AuthError.notAuthenticated }
        return session.userId
    }
}
