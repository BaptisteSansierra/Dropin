//
//  ImageRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import Foundation

/// Sync-facing reference returned to SyncService for push. Data is non-optional here because
/// only locally-created (not-yet-pushed) images appear in this list — those always have data.
struct ImageRef: Sendable, Equatable {
    let id: UUID
    let placeId: UUID
    let thumbnail: Data
    let full: Data
}

@MainActor
protocol ImageRepository: Sendable {
    // UI / use cases
    func add(placeId: UUID, thumbnail: Data, full: Data) async throws -> UUID
    /// Soft-delete. SyncService finalizes with hardDelete after remote delete succeeds.
    func remove(id: UUID) async throws
    /// Returns currently-cached state. `thumbnail` is nil for images pulled from remote that haven't been downloaded yet.
    func fetchThumbnails(placeId: UUID) async throws -> [(id: UUID, thumbnail: Data?)]
    /// Returns the cached full data, or nil if not yet downloaded.
    func fetchFull(id: UUID) async throws -> Data?
    /// Place id for an image — needed by the lazy loader to construct remote storage paths.
    func fetchPlaceId(imageId: UUID) async throws -> UUID?
    /// Populates cached data after a successful remote download.
    func cacheThumbnail(id: UUID, data: Data) async throws
    func cacheFull(id: UUID, data: Data) async throws

    // Sync-facing
    func fetchUnsynced() async throws -> [ImageRef]
    func fetchPendingDelete() async throws -> [(id: UUID, placeId: UUID)]
    func markSynced(id: UUID) async throws
    func hardDelete(id: UUID) async throws
    /// Inserts an empty stub for an image discovered on remote. Data is downloaded lazily on demand.
    func insertSynced(id: UUID, placeId: UUID) async throws
    func localImageIds(placeId: UUID) async throws -> Set<UUID>
}
