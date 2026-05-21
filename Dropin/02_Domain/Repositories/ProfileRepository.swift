//
//  ProfileRepository.swift
//  Dropin
//

import Foundation

@MainActor
protocol ProfileRepository: Sendable {
    /// Returns the cached profile (nil if it hasn't been pulled yet).
    func fetch() async throws -> ProfileEntity?
    /// Upserts the local row from a remote pull or a freshly bumped local copy.
    /// Bumps the dirty marker via the syncing decorator (set syncedAt=nil) when
    /// the change originated locally.
    func upsert(_ profile: ProfileEntity) async throws
    /// Bumps `updatedAt` on the local row, returning the updated entity so the
    /// caller (typically ProfileService) can republish it to the UI right away.
    func update(displayName: String?) async throws -> ProfileEntity
}
