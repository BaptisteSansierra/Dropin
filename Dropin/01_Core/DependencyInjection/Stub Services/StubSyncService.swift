//
//  StubSyncService.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

//  No-op sync services used by MockContainer (previews + tests)
//  so the app target can be built without real Supabase credentials.
#if DEBUG

import Foundation

@MainActor
final class StubSyncService: SyncServiceProtocol, SyncServicePausableProtocol {
    var syncStatus: SyncStatus = SyncStatus()
    var pendingChangeCount: Int { 0 }
    func markPlaceDirty(_ id: UUID) {}
    func markCategoryDirty(_ id: UUID) {}
    func markTagDirty(_ id: UUID) {}
    func markImagesChanged() {}
    func markProfileDirty() {}
    func syncAll() async {}
    func reset() {}
    func withPausedPushes<T>(_ body: () async throws -> T) async rethrows -> T {
        try await body()
    }
}

#endif
