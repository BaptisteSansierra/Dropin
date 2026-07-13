//
//  SupabaseImageRepository.swift
//  Dropin
//

import Supabase
import Foundation

final class SupabaseImageRepository: RemoteImageRepository {
    private let client: SupabaseClient
    private let auth: any AuthServiceProtocol
    private let bucket = "place-images"

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

    func upload(imageId: UUID, placeId: UUID, full: Data, thumbnail: Data) async throws {
        let userId = try await requireUserId()
        let fullPath  = Self.fullPath(userId: userId, placeId: placeId, imageId: imageId)
        let thumbPath = Self.thumbPath(userId: userId, placeId: placeId, imageId: imageId)
        let opts = FileOptions(contentType: "image/jpeg", upsert: true)
        try await client.storage.from(bucket).upload(fullPath,  data: full, options: opts)
        try await client.storage.from(bucket).upload(thumbPath, data: thumbnail, options: opts)
        let dto = SupabaseImageDTO(id: imageId, userId: userId, placeId: placeId, createdAt: Date())
        try await client.from("images").upsert(dto, onConflict: "id").execute()
    }

    func delete(imageId: UUID, placeId: UUID) async throws {
        let userId = try await requireUserId()
        let paths = [Self.fullPath(userId: userId, placeId: placeId, imageId: imageId),
                     Self.thumbPath(userId: userId, placeId: placeId, imageId: imageId)]
        // Storage remove tolerates missing paths.
        _ = try? await client.storage.from(bucket).remove(paths: paths)
        try await client.from("images").delete().eq("id", value: imageId).execute()
    }

    func downloadThumbnail(imageId: UUID, placeId: UUID) async throws -> Data? {
        let userId = try await requireUserId()
        return try await download(path: Self.thumbPath(userId: userId, placeId: placeId, imageId: imageId))
    }

    func downloadFull(imageId: UUID, placeId: UUID) async throws -> Data? {
        let userId = try await requireUserId()
        return try await download(path: Self.fullPath(userId: userId, placeId: placeId, imageId: imageId))
    }

    func fetch(createdAfter date: Date) async throws -> [RemoteImageRef] {
        _ = try await requireUserId()
        let dateStr = Self.dateFormatter.string(from: date)
        let dtos: [SupabaseImageDTO] = try await client
            .from("images")
            .select()
            .gt("created_at", value: dateStr)
            .execute()
            .value
        return dtos.map { RemoteImageRef(id: $0.id, placeId: $0.placeId, createdAt: $0.createdAt) }
    }

    // MARK: - Private

    @MainActor
    private func requireUserId() throws -> UUID {
        guard let session = auth.session else { throw AuthServiceError.notAuthenticated }
        return session.userId
    }

    private func download(path: String) async throws -> Data? {
        do {
            return try await client.storage.from(bucket).download(path: path)
        } catch {
            // Treat missing-object as nil so callers can show a placeholder rather than crash.
            return nil
        }
    }

    private static func fullPath(userId: UUID, placeId: UUID, imageId: UUID) -> String {
        "\(userId.uuidString)/\(placeId.uuidString)/\(imageId.uuidString).jpg"
    }

    private static func thumbPath(userId: UUID, placeId: UUID, imageId: UUID) -> String {
        "\(userId.uuidString)/\(placeId.uuidString)/\(imageId.uuidString)_thumb.jpg"
    }
}
