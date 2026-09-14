//
//  MockRemoteGroupRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockRemoteGroupRepository: RemoteGroupRepository, @unchecked Sendable {
    private(set) var upsertedGroups: [GroupEntity] = []
    var groupsToReturn: [GroupEntity]
    var shouldThrowOnUpsert = false

    init(groupsToReturn: [GroupEntity] = []) {
        self.groupsToReturn = groupsToReturn
    }

    func upsert(_ group: GroupEntity) async throws {
        if shouldThrowOnUpsert { throw MockSyncError.intentional }
        upsertedGroups.append(group)
    }

    func fetch(updatedAfter date: Date) async throws -> [GroupEntity] {
        return groupsToReturn
    }
}
