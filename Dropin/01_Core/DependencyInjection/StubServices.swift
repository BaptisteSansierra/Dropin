//
//  StubServices.swift
//  Dropin
//
//  No-op auth and sync services used by MockContainer (previews + tests)
//  so the app target can be built without real Supabase credentials.
//

#if DEBUG

import Foundation

@MainActor
final class StubAuthService: AuthServiceProtocol {
    var session: UserSession? = nil
    var isAuthenticated: Bool { session != nil }
    func signUp(email: String, password: String) async throws {}
    func signIn(email: String, password: String) async throws {}
    func signInWithApple() async throws {}
    func signOut() async throws { session = nil }
    func restoreSession() async {}
}

final class StubRemoteProfileRepository: RemoteProfileRepository {
    func fetch() async throws -> ProfileEntity? { nil }
    func fetch(updatedAfter date: Date) async throws -> ProfileEntity? { nil }
    func upsert(_ profile: ProfileEntity) async throws {}
}

final class StubRemoteImageRepository: RemoteImageRepository {
    func upload(imageId: UUID, placeId: UUID, full: Data, thumbnail: Data) async throws {}
    func delete(imageId: UUID, placeId: UUID) async throws {}
    func downloadThumbnail(imageId: UUID, placeId: UUID) async throws -> Data? { nil }
    func downloadFull(imageId: UUID, placeId: UUID) async throws -> Data? { nil }
    func fetch(createdAfter date: Date) async throws -> [RemoteImageRef] { [] }
}

@MainActor
final class StubSyncService: SyncServiceProtocol, SyncServicePausableProtocol {
    var syncStatus: SyncStatus = SyncStatus()
    func markPlaceDirty(_ id: UUID) {}
    func markGroupDirty(_ id: UUID) {}
    func markTagDirty(_ id: UUID) {}
    func markImagesChanged() {}
    func markProfileDirty() {}
    func syncAll() async {}
    func withPausedPushes<T>(_ body: () async throws -> T) async rethrows -> T {
        try await body()
    }
}

@MainActor
final class StubProfileService: ProfileServiceProtocol {
    var profile: ProfileEntity? = nil
    func load() async {}
    func setDisplayName(_ newValue: String?) async throws { /* no-op */ }
    func clear() { profile = nil }
}

#endif
