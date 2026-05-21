//
//  RemoteImageRepository.swift
//  Dropin
//

import Foundation

struct RemoteImageRef: Sendable, Equatable {
    let id: UUID
    let placeId: UUID
    let createdAt: Date
}

/// Non-isolated by design: network work shouldn't be pinned to the main thread, and
/// callers from arbitrary actor contexts (notably the ImageLoader actor) need to invoke
/// these methods without forcing a MainActor hop.
protocol RemoteImageRepository: Sendable {
    /// Uploads full + thumb to Storage, then inserts the metadata row.
    /// Order matters: storage objects must exist before the row references them.
    func upload(imageId: UUID, placeId: UUID, full: Data, thumbnail: Data) async throws
    /// Deletes the storage objects AND the metadata row. Idempotent — silently succeeds if any piece is already gone.
    func delete(imageId: UUID, placeId: UUID) async throws
    /// Returns nil if the storage object is missing (treated as "image lost").
    func downloadThumbnail(imageId: UUID, placeId: UUID) async throws -> Data?
    func downloadFull(imageId: UUID, placeId: UUID) async throws -> Data?
    /// Image rows created strictly after `date`. Images are immutable so created_at is the cursor.
    func fetch(createdAfter date: Date) async throws -> [RemoteImageRef]
}
