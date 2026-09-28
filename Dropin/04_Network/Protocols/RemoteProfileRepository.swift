//
//  RemoteProfileRepository.swift
//  Dropin
//

import Foundation

/// Non-isolated by design (same rationale as the other Remote* protocols).
protocol RemoteProfileRepository: Sendable {
    /// Fetches the signed-in user's profile (single row scoped by RLS).
    /// Returns nil if for some reason the row doesn't exist yet.
    func fetch() async throws -> Profile?
    /// Pulls only if the row was updated after `date`. Returns nil otherwise.
    func fetch(updatedAfter date: Date) async throws -> Profile?
    /// Upserts the profile row. RLS rejects anything where `id != auth.uid()`.
    func upsert(_ profile: Profile) async throws
}
