//
//  MockRemoteProfileRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockRemoteProfileRepository: RemoteProfileRepository, @unchecked Sendable {
    var profileToReturn: ProfileEntity?
    private(set) var upserted: [ProfileEntity] = []
    var shouldThrowOnUpsert = false

    init(profileToReturn: ProfileEntity? = nil) {
        self.profileToReturn = profileToReturn
    }

    func fetch() async throws -> ProfileEntity? { profileToReturn }

    func fetch(updatedAfter date: Date) async throws -> ProfileEntity? {
        guard let p = profileToReturn, p.updatedAt > date else { return nil }
        return p
    }

    func upsert(_ profile: ProfileEntity) async throws {
        if shouldThrowOnUpsert { throw MockSyncError.intentional }
        upserted.append(profile)
    }
}
