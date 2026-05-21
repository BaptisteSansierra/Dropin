//
//  ImageLoader.swift
//  Dropin
//
//  Dedicated actor that coordinates lazy image downloads. Tracks three things:
//   - in-flight downloads, so concurrent requests for the same image join one task
//   - failed downloads, so a transient failure isn't retried again this session
//   - everything else is read from / written to the local cache via ImageRepository
//
//  Callers see a tri-state result instead of nil: cached(Data) / downloading / failed.
//

import Foundation

enum ImageLoadState: Sendable, Equatable {
    case cached(Data)
    case downloading
    case failed   // transient (network etc.) — retried next session
    case missing  // storage 404 — file is permanently gone

    var data: Data? {
        if case .cached(let d) = self { return d }
        return nil
    }
}

actor ImageLoader {

    private enum Kind { case thumb, full }
    private struct Key: Hashable { let kind: Kind; let id: UUID }

    private nonisolated let local: any ImageRepository
    private nonisolated let remote: any RemoteImageRepository
    private var tasks: [Key: Task<ImageLoadState, Never>] = [:]
    private var failed: Set<Key> = []
    // No `missing` set: a 404 means another device already ran the full remote delete
    // (our own upload writes the DB row last, so storage-without-row is essentially
    // impossible under normal operation). We just clean up our local stub and on the
    // next reload the entry is naturally absent from `local.fetchThumbnails`.

    init(local: any ImageRepository, remote: any RemoteImageRepository) {
        self.local = local
        self.remote = remote
    }

    /// Initial state snapshot for every thumbnail of a place.
    /// Kicks off downloads for any not-yet-cached entries.
    /// Follow up with `awaitThumbnail` for `.downloading` entries to update the UI when each one finishes.
    func thumbnails(for placeId: UUID) async throws -> [(id: UUID, state: ImageLoadState)] {
        let cached = try await local.fetchThumbnails(placeId: placeId)
        return cached.map { entry in
            (entry.id, ensureThumbnail(imageId: entry.id, placeId: placeId, cached: entry.thumbnail))
        }
    }

    /// Awaits the final state for a thumbnail's in-flight download. If the task has already
    /// completed, re-reads the cache (success) or returns `.failed`.
    func awaitThumbnail(imageId: UUID, placeId: UUID) async -> ImageLoadState {
        let key = Key(kind: .thumb, id: imageId)
        if let task = tasks[key] {
            // Download ongoing, wait for its return value
            return await task.value
        }
        if failed.contains(key) {
            // Download already ended and failed
            return .failed
        }
        if let entry = try? await local.fetchThumbnails(placeId: placeId).first(where: { $0.id == imageId }),
           let data = entry.thumbnail {
            // Download already ended, the data is stored, return it
            return .cached(data)
        }
        // Stub was cleaned up after a 404 — image is gone
        return .missing
    }

    /// State for a full image. Kicks off a download if not cached / failed / in-flight.
    func full(imageId: UUID, placeId: UUID) async -> ImageLoadState {
        if let cachedData = try? await local.fetchFull(id: imageId) {
            return .cached(cachedData)
        }
        let key = Key(kind: .full, id: imageId)
        if failed.contains(key) { return .failed }
        if let task = tasks[key] { return await task.value }
        tasks[key] = makeFullTask(imageId: imageId, placeId: placeId)
        return .downloading
    }

    /// Clears the failed flag so the next request retries.
    func retryThumbnail(imageId: UUID) { failed.remove(Key(kind: .thumb, id: imageId)) }
    func retryFull(imageId: UUID) { failed.remove(Key(kind: .full, id: imageId)) }

    // MARK: - Private

    private func ensureThumbnail(imageId: UUID, placeId: UUID, cached: Data?) -> ImageLoadState {
        if let data = cached { return .cached(data) }
        let key = Key(kind: .thumb, id: imageId)
        if failed.contains(key) { return .failed }
        if tasks[key] != nil { return .downloading }
        tasks[key] = makeThumbnailTask(imageId: imageId, placeId: placeId)
        return .downloading
    }

    private func makeThumbnailTask(imageId: UUID, placeId: UUID) -> Task<ImageLoadState, Never> {
        Task { [weak self] in
            guard let self else { return .failed }
            return await self.runThumbnailDownload(imageId: imageId, placeId: placeId)
        }
    }

    private func makeFullTask(imageId: UUID, placeId: UUID) -> Task<ImageLoadState, Never> {
        Task { [weak self] in
            guard let self else { return .failed }
            return await self.runFullDownload(imageId: imageId, placeId: placeId)
        }
    }

    private func runThumbnailDownload(imageId: UUID, placeId: UUID) async -> ImageLoadState {
        let key = Key(kind: .thumb, id: imageId)
        let result: ImageLoadState
        do {
            if let data = try await remote.downloadThumbnail(imageId: imageId, placeId: placeId) {
                try? await local.cacheThumbnail(id: imageId, data: data)
                result = .cached(data)
            } else {
                await cleanupMissing(imageId: imageId)
                result = .missing
            }
        } catch {
            assertNoBug(error)
            Log.error("ImageLoader: thumbnail \(imageId) failed: \(error)")
            failed.insert(key)
            result = .failed
        }
        tasks[key] = nil
        return result
    }

    private func runFullDownload(imageId: UUID, placeId: UUID) async -> ImageLoadState {
        let key = Key(kind: .full, id: imageId)
        let result: ImageLoadState
        do {
            if let data = try await remote.downloadFull(imageId: imageId, placeId: placeId) {
                try? await local.cacheFull(id: imageId, data: data)
                result = .cached(data)
            } else {
                await cleanupMissing(imageId: imageId)
                result = .missing
            }
        } catch {
            assertNoBug(error)
            Log.error("ImageLoader: full \(imageId) failed: \(error)")
            failed.insert(key)
            result = .failed
        }
        tasks[key] = nil
        return result
    }

    /// Storage 404 = another device already deleted this image (storage + DB row).
    /// We only need to catch up our local view; no remote call needed.
    private func cleanupMissing(imageId: UUID) async {
        do {
            try await local.hardDelete(id: imageId)
        } catch {
            assertNoBug(error)
            Log.error("ImageLoader: hardDelete stub \(imageId) failed: \(error)")
        }
    }
}
