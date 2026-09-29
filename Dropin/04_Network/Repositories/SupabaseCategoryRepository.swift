//
//  SupabaseCategoryRepository.swift
//  Dropin

import Supabase
import Foundation

final class SupabaseCategoryRepository: RemoteCategoryRepository {
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

    func upsert(_ category: Category) async throws {
        let userId = try await requireUserId()
        let dto = SupabaseCategoryDTO(from: category, userId: userId)
        try await client.from("categories").upsert(dto, onConflict: "id").execute()
    }

    func fetch(updatedAfter date: Date, excludeDeleted: Bool) async throws -> [Category] {
        _ = try await requireUserId()
        let dateStr = Self.dateFormatter.string(from: date)
        let dtos: [SupabaseCategoryDTO] = try await SupabasePaginator.fetchAll { from, to in
            var query = client
                .from("categories")
                .select()
                .gte("updated_at", value: dateStr)
            if excludeDeleted {
                query = query.is("deleted_at", value: nil)
            }
            return query
                .order("id")
                .range(from: from, to: to)
        }
        return dtos.map { $0.toDomain() }
    }

    @MainActor
    private func requireUserId() throws -> UUID {
        guard let session = auth.session else { throw AuthServiceError.notAuthenticated }
        return session.userId
    }
}
