//
//  SupabaseTagRepository.swift
//  Dropin

import Supabase
import Foundation

final class SupabaseTagRepository: RemoteTagRepository {
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

    func upsert(_ tag: TagEntity) async throws {
        let userId = try await requireUserId()
        let dto = SupabaseTagDTO(from: tag, userId: userId)
        try await client.from("tags").upsert(dto, onConflict: "id").execute()
    }

    func fetch(updatedAfter date: Date) async throws -> [TagEntity] {
        _ = try await requireUserId()
        let dateStr = Self.dateFormatter.string(from: date)
        let dtos: [SupabaseTagDTO] = try await client
            .from("tags")
            .select()
            .gte("updated_at", value: dateStr)
            .execute()
            .value
        return dtos.map { $0.toDomain() }
    }

    @MainActor
    private func requireUserId() throws -> UUID {
        guard let session = auth.session else { throw AuthServiceError.notAuthenticated }
        return session.userId
    }
}
