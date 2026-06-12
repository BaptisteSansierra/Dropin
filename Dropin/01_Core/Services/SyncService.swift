//
//  SyncService.swift
//  Dropin

import Foundation

@MainActor
protocol SyncServiceProtocol: AnyObject {
    var syncStatus: SyncStatus { get }
    /// Total number of pending dirty entities (places + groups + tags + profile).
    /// Used by sign-out to warn the user about unsynced data.
    var pendingChangeCount: Int { get }
    func markPlaceDirty(_ id: UUID)
    func markGroupDirty(_ id: UUID)
    func markTagDirty(_ id: UUID)
    func markImagesChanged()
    func markProfileDirty()
    func syncAll() async
    func reset()
}

/// Narrow surface for callers that only need to batch a series of mutations
/// without triggering a remote push per mutation. The closure-based shape
/// guarantees pushes are always resumed, even if `body` throws.
@MainActor
protocol SyncServicePausableProtocol: AnyObject {
    func withPausedPushes<T>(_ body: () async throws -> T) async rethrows -> T
}

@MainActor
@Observable final class SyncStatus {
    fileprivate(set) var isSyncing: Bool
    fileprivate(set) var lastSyncedAt: Date?

    init() {
        self.isSyncing = false
        self.lastSyncedAt = nil
    }
}

@MainActor
final class SyncService: SyncServiceProtocol, SyncServicePausableProtocol {

    // MARK: - Observable state
    private(set) var syncStatus: SyncStatus

    // MARK: - Dirty sets (pending push)
    private var dirtyPlaceIds: Set<UUID> = []
    private var dirtyGroupIds: Set<UUID> = []
    private var dirtyTagIds: Set<UUID> = []
    // Profile is single-row; a bool suffices.
    private var dirtyProfile = false
    // Image dirty state lives on SDImage itself (syncedAt == nil OR deletedAt != nil),
    // so no in-memory set is needed.

    // Single-flight push guard: coalesces bursts of mark*Dirty into one push.
    // `pendingPush` is set when a mark*Dirty arrives during an in-flight push,
    // ensuring the loop runs one more time so the new dirty IDs aren't stranded.
    private var pushTask: Task<Void, Never>?
    private var pendingPush: Bool = false

    // Batch primitive: when true, mark*Dirty still accumulates IDs in the dirty
    // sets but does NOT fire a push task. Set via `withPausedPushes`.
    private var pushesPaused: Bool = false

    // MARK: - Pending change accounting
    var pendingChangeCount: Int {
        dirtyPlaceIds.count
        + dirtyGroupIds.count
        + dirtyTagIds.count
        + (dirtyProfile ? 1 : 0)
    }

    // MARK: - Dependencies
    private let localPlaceRepo: any PlaceRepository
    private let localGroupRepo: any GroupRepository
    private let localTagRepo: any TagRepository
    private let localImageRepo: any ImageRepository
    private let localProfileRepo: any ProfileRepository
    private let remotePlaceRepo: any RemotePlaceRepository
    private let remoteGroupRepo: any RemoteGroupRepository
    private let remoteTagRepo: any RemoteTagRepository
    private let remoteImageRepo: any RemoteImageRepository
    private let remoteProfileRepo: any RemoteProfileRepository
    private let reachability: any ReachabilityServiceProtocol
    private let userDefaults: UserDefaults

    init(localPlaceRepo: any PlaceRepository,
         localGroupRepo: any GroupRepository,
         localTagRepo: any TagRepository,
         localImageRepo: any ImageRepository,
         localProfileRepo: any ProfileRepository,
         remotePlaceRepo: any RemotePlaceRepository,
         remoteGroupRepo: any RemoteGroupRepository,
         remoteTagRepo: any RemoteTagRepository,
         remoteImageRepo: any RemoteImageRepository,
         remoteProfileRepo: any RemoteProfileRepository,
         reachability: any ReachabilityServiceProtocol,
         userDefaults: UserDefaults = .standard) {
        self.localPlaceRepo = localPlaceRepo
        self.localGroupRepo = localGroupRepo
        self.localTagRepo = localTagRepo
        self.localImageRepo = localImageRepo
        self.localProfileRepo = localProfileRepo
        self.remotePlaceRepo = remotePlaceRepo
        self.remoteGroupRepo = remoteGroupRepo
        self.remoteTagRepo = remoteTagRepo
        self.remoteImageRepo = remoteImageRepo
        self.remoteProfileRepo = remoteProfileRepo
        self.reachability = reachability
        self.syncStatus = SyncStatus()
        self.userDefaults = userDefaults
        if let lastSync = userDefaults.object(forKey: DropinApp.userDefaultsKeys.lastSyncedAt) as? Date {
            self.syncStatus.lastSyncedAt = lastSync
        }
    }

    // MARK: - SyncServiceProtocol
    func reset() {
        // Reset last sync date
        userDefaults.removeObject(forKey: DropinApp.userDefaultsKeys.lastSyncedAt)
        // Reset sync status
        syncStatus = SyncStatus()
        // Reset pending operations
        dirtyPlaceIds.removeAll()
        dirtyGroupIds.removeAll()
        dirtyTagIds.removeAll()
        dirtyProfile = false
    }

    func markPlaceDirty(_ id: UUID) {
        dirtyPlaceIds.insert(id)
        schedulePush()
    }

    func markGroupDirty(_ id: UUID) {
        dirtyGroupIds.insert(id)
        schedulePush()
    }

    func markTagDirty(_ id: UUID) {
        dirtyTagIds.insert(id)
        schedulePush()
    }

    /// Images carry their own dirty state on SDImage — this just nudges a push attempt.
    func markImagesChanged() {
        schedulePush()
    }

    func markProfileDirty() {
        dirtyProfile = true
        schedulePush()
    }

    /// Pull remote changes then flush dirty queue. No-op if already syncing.
    func syncAll() async {
        guard !syncStatus.isSyncing else { return }
        guard reachability.isConnected else { return }
        syncStatus.isSyncing = true
        defer { syncStatus.isSyncing = false }
        await pull()
        await pushIfOnline()
    }

    // MARK: - SyncServicePausableProtocol

    func withPausedPushes<T>(_ body: () async throws -> T) async rethrows -> T {
        pushesPaused = true
        defer {
            pushesPaused = false
            schedulePush()   // one flush for everything that accumulated
        }
        return try await body()
    }

    // MARK: - Private

    /// Single-flight: at most one push task at a time. If a `mark*Dirty` lands
    /// while a push is in flight, `pendingPush` makes the loop run one more
    /// time so IDs added after their step's drain still get pushed.
    /// While `pushesPaused` is true, mark*Dirty still accumulates IDs but no
    /// push task is fired — the flush happens when the pause is lifted.
    private func schedulePush() {
        guard !pushesPaused else { return }
        guard pushTask == nil else { pendingPush = true; return }
        pushTask = Task {
            await self.runPushLoop()
        }
    }

    private func runPushLoop() async {
        defer { pushTask = nil }
        repeat {
            pendingPush = false
            await pushIfOnline()
        } while pendingPush
    }

    private func pushIfOnline() async {
        guard reachability.isConnected else { return }
        await push()
    }

    private func push() async {
        // Push order matters because of Postgres FK constraints:
        //   - images.place_id references places.id → places must exist remotely before image rows
        // Profile is independent of everything else; tags/groups have no FK from places
        // (places.tag_ids[] and group_id are unconstrained), but we still push them
        // before places for symmetry with pull.
        await pushDirtyProfile()
        await pushDirtyTags()
        await pushDirtyGroups()
        await pushDirtyPlaces()
        await pushDirtyImages()
        await pushDeletedImages()
    }

    private func pushDirtyProfile() async {
        guard dirtyProfile else { return }
        // Drain up-front so a concurrent markProfileDirty during the awaits
        // below stays sticky for the next push, not this one.
        dirtyProfile = false
        do {
            guard let profile = try await localProfileRepo.fetch() else { return }
            try await remoteProfileRepo.upsert(profile)
            Log.debug("Remote upsert PROFILE \(profile.id)")
        } catch {
            dirtyProfile = true   // re-arm on failure
            assertNoBug(error)
            Log.error("SyncService: push profile failed: \(error)")
        }
    }

    private func pushDirtyPlaces() async {
        let ids = dirtyPlaceIds
        dirtyPlaceIds.removeAll()
        for id in ids {
            do {
                let place = try await localPlaceRepo.fetch(id)
                try await remotePlaceRepo.upsert(place)
                Log.debug("Remote upsert PLACE \(place.name)")
            } catch {
                dirtyPlaceIds.insert(id)
                assertNoBug(error)
                Log.error("SyncService: push place \(id) failed: \(error)")
            }
        }
    }

    private func pushDirtyGroups() async {
        let ids = dirtyGroupIds
        dirtyGroupIds.removeAll()
        for id in ids {
            do {
                let group = try await localGroupRepo.fetch(id)
                try await remoteGroupRepo.upsert(group)
                Log.debug("Remote upsert GROUP \(group.name)")
            } catch {
                dirtyGroupIds.insert(id)
                assertNoBug(error)
                Log.error("SyncService: push group \(id) failed: \(error)")
            }
        }
    }

    private func pushDirtyTags() async {
        let ids = dirtyTagIds
        dirtyTagIds.removeAll()
        for id in ids {
            do {
                let tag = try await localTagRepo.fetch(id)
                try await remoteTagRepo.upsert(tag)
                Log.debug("Remote upsert TAG \(tag.name)")
            } catch {
                dirtyTagIds.insert(id)
                assertNoBug(error)
                Log.error("SyncService: push tag \(id) failed: \(error)")
            }
        }
    }

    private func pushDirtyImages() async {
        do {
            let refs = try await localImageRepo.fetchUnsynced()
            for ref in refs {
                do {
                    try await remoteImageRepo.upload(imageId: ref.id,
                                                     placeId: ref.placeId,
                                                     full: ref.full,
                                                     thumbnail: ref.thumbnail)
                    try await localImageRepo.markSynced(id: ref.id)
                } catch {
                    assertNoBug(error)
                    Log.error("SyncService: push image \(ref.id) failed: \(error)")
                }
            }
        } catch {
            assertNoBug(error)
            Log.error("SyncService: fetchUnsynced failed: \(error)")
        }
    }

    private func pushDeletedImages() async {
        do {
            let pending = try await localImageRepo.fetchPendingDelete()
            for (id, placeId) in pending {
                do {
                    try await remoteImageRepo.delete(imageId: id, placeId: placeId)
                    try await localImageRepo.hardDelete(id: id)
                } catch {
                    assertNoBug(error)
                    Log.error("SyncService: delete image \(id) failed: \(error)")
                }
            }
        } catch {
            assertNoBug(error)
            Log.error("SyncService: fetchPendingDelete failed: \(error)")
        }
    }

    private func pull() async {
        let since = syncStatus.lastSyncedAt ?? .distantPast
        do {
            Log.debug("PULL since \(since) ...")
            let profile = try await remoteProfileRepo.fetch(updatedAfter: since)
            let places  = try await remotePlaceRepo.fetch(updatedAfter: since)
            let groups  = try await remoteGroupRepo.fetch(updatedAfter: since)
            let tags    = try await remoteTagRepo.fetch(updatedAfter: since)
            Log.debug(" > PULLED \(places.count) places")

            // Pull order matters because of local linkage:
            //   - Profile has no relationship to other tables; can be applied first.
            //   - PlaceRepositoryImpl resolves tag_ids / group_id by looking them up in SwiftData,
            //     so tags and groups must be upserted locally before places.
            //   - SDImage.place is a SwiftData relationship → places must exist locally before
            //     images are inserted.
            if let profile { try await localProfileRepo.upsert(profile) }
            for tag   in tags   { try await localTagRepo.upsert(tag) }
            for group in groups { try await localGroupRepo.upsert(group) }
            for place in places { try await localPlaceRepo.upsert(place) }

            // lazy ImageLoader: this doesn't download bytes anymore, only inserts metadata stubs.
            await pullImages(since: since)

            syncStatus.lastSyncedAt = Date()
            Log.debug("Set last sync at \(syncStatus.lastSyncedAt!)")
            userDefaults.set(syncStatus.lastSyncedAt, forKey: DropinApp.userDefaultsKeys.lastSyncedAt)
        } catch {
            assertNoBug(error)
            Log.error("SyncService: pull failed: \(error)")
        }
    }

    /// Inserts metadata-only stubs for newly discovered remote images. Binary data
    /// (thumbnail + full) is fetched lazily on demand by GetPlaceThumbnails / GetPlaceImage.
    private func pullImages(since: Date) async {
        do {
            let remoteRefs = try await remoteImageRepo.fetch(createdAfter: since)
            for ref in remoteRefs {
                do {
                    let knownIds = try await localImageRepo.localImageIds(placeId: ref.placeId)
                    if knownIds.contains(ref.id) { continue }
                    try await localImageRepo.insertSynced(id: ref.id, placeId: ref.placeId)
                } catch {
                    assertNoBug(error)
                    Log.error("SyncService: pull image \(ref.id) failed: \(error)")
                }
            }
        } catch {
            assertNoBug(error)
            Log.error("SyncService: pullImages failed: \(error)")
        }
    }
}
