//
//  MockRemoteProfileRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockRemoteProfileRepository: RemoteProfileRepository, @unchecked Sendable {
    var profileToReturn: Profile?
    private(set) var upserted: [Profile] = []
    var shouldThrowOnUpsert = false

    init(profileToReturn: Profile? = nil) {
        self.profileToReturn = profileToReturn
    }

    func fetch() async throws -> Profile? { profileToReturn }

    func fetch(updatedAfter date: Date) async throws -> Profile? {
        guard let p = profileToReturn, p.updatedAt > date else { return nil }
        return p
    }

    func upsert(_ profile: Profile) async throws {
        if shouldThrowOnUpsert { throw MockSyncError.intentional }
        upserted.append(profile)
    }
}
