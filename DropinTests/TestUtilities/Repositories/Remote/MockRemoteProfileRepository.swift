//
//  MockRemoteProfileRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockRemoteProfileRepository: RemoteProfileRepository, @unchecked Sendable {
    var profileToReturn: Profile?
    private(set) var updatedDisplayNames: [Profile] = []
    var shouldThrowOnUpdate = false

    init(profileToReturn: Profile? = nil) {
        self.profileToReturn = profileToReturn
    }

    func fetch() async throws -> Profile? { profileToReturn }

    func fetch(updatedAfter date: Date) async throws -> Profile? {
        guard let p = profileToReturn, p.updatedAt > date else { return nil }
        return p
    }

    func updateDisplayName(_ profile: Profile) async throws {
        if shouldThrowOnUpdate { throw MockSyncError.intentional }
        updatedDisplayNames.append(profile)
    }
}
