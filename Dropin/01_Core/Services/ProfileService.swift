//
//  ProfileService.swift
//  Dropin
//
//  Holds the signed-in user's profile and republishes it to the UI. Loaded by
//  AuthService after sign-in / session restore; cleared on sign-out.
//
//  Source of truth flow:
//    - First load on a fresh device: fetch remote → upsert local → publish
//    - Subsequent loads: read local cache → publish; SyncService keeps it fresh
//    - Local edits: ProfileService.setDisplayName → local repo (bumps updatedAt,
//      clears syncedAt via the syncing decorator) → republish → SyncService pushes
//

import Foundation

@MainActor
protocol ProfileServiceProtocol: AnyObject {
    var profile: ProfileEntity? { get }
    /// Loads the profile from the local cache, falling back to a remote fetch if
    /// nothing is cached yet. Safe to call repeatedly.
    func load() async
    /// Updates display_name locally and queues the push.
    func setDisplayName(_ newValue: String?) async throws
    /// Drops the cached profile (used by sign-out).
    func clear()
}

@Observable
@MainActor
final class ProfileService: ProfileServiceProtocol {

    private(set) var profile: ProfileEntity?

    @ObservationIgnored private let local: any ProfileRepository
    @ObservationIgnored private let remote: any RemoteProfileRepository

    init(local: any ProfileRepository, remote: any RemoteProfileRepository) {
        self.local = local
        self.remote = remote
    }

    func load() async {
        do {
            if let cached = try await local.fetch() {
                profile = cached
                return
            }
            // No local cache yet — fetch once from remote and seed local.
            guard let remoteProfile = try await remote.fetch() else {
                Log.error("ProfileService: remote profile not found")
                return
            }
            try await local.upsert(remoteProfile)
            profile = remoteProfile
        } catch {
            assertNoBug(error)
            Log.error("ProfileService: load failed: \(error)")
        }
    }

    func setDisplayName(_ newValue: String?) async throws {
        let updated = try await local.update(displayName: newValue)
        profile = updated
    }

    func clear() {
        profile = nil
    }
}
