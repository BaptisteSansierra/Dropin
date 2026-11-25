//
//  MockRemoteSpaceRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockRemoteSpaceRepository: RemoteSpaceRepository, @unchecked Sendable {
    private(set) var upsertedSpaces: [Space] = []
    var spacesToReturn: [Space]
    var shouldThrowOnUpsert = false

    init(spacesToReturn: [Space] = []) {
        self.spacesToReturn = spacesToReturn
    }

    func upsert(_ space: Space) async throws {
        if shouldThrowOnUpsert { throw MockSyncError.intentional }
        upsertedSpaces.append(space)
    }

    func fetch(updatedAfter date: Date, excludeDeleted: Bool) async throws -> [Space] {
        excludeDeleted ? spacesToReturn.filter { $0.deletedAt == nil } : spacesToReturn
    }
}
