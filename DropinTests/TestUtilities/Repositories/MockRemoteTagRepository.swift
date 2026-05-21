//
//  MockRemoteTagRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockRemoteTagRepository: RemoteTagRepository, @unchecked Sendable {
    private(set) var upsertedTags: [TagEntity] = []
    var tagsToReturn: [TagEntity]
    var shouldThrowOnUpsert = false

    init(tagsToReturn: [TagEntity] = []) {
        self.tagsToReturn = tagsToReturn
    }

    func upsert(_ tag: TagEntity) async throws {
        if shouldThrowOnUpsert { throw MockSyncError.intentional }
        upsertedTags.append(tag)
    }

    func fetch(updatedAfter date: Date) async throws -> [TagEntity] {
        return tagsToReturn
    }
}
