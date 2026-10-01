//
//  SupabasePlaceRepository.swift
//  Dropin

import Supabase
import Foundation

final class SupabasePlaceRepository: RemotePlaceRepository {
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

    func upsert(_ place: Place) async throws {
        let userId = try await requireUserId()
        let dto = SupabasePlaceDTO(from: place, userId: userId)
        //Log.debug("UPSERT PLACE DTO with GROUP:\(dto.categoryId)")
        try await client.from("places").upsert(dto, onConflict: "id").execute()
        //let confirmObj = try await fetch(placeId: dto.id)
        //Log.debug("UPTODATE PLACE with GROUP:\(confirmObj?.category?.id)")
    }

    // DEBUG purpose
    func fetch(placeId: UUID) async throws -> Place? {
        _ = try await requireUserId()
        let dtos: [SupabasePlaceDTO] = try await client
            .from("places")
            .select()
            .gte("id", value: placeId)
            .execute()
            .value
        return dtos.map { $0.toDomain() }.first
    }

    func fetch(updatedAfter date: Date, excludeDeleted: Bool) async throws -> [Place] {
        _ = try await requireUserId()
        let dateStr = Self.dateFormatter.string(from: date)
        let dtos: [SupabasePlaceDTO] = try await SupabasePaginator.fetchAll { from, to in
            var query = client
                .from("places")
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
