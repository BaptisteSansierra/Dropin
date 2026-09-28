//
//  MockRemoteTagRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockRemoteTagRepository: RemoteTagRepository, @unchecked Sendable {
    private(set) var upsertedTags: [Dropin.Tag] = []
    var tagsToReturn: [Dropin.Tag]
    var shouldThrowOnUpsert = false

    init(tagsToReturn: [Dropin.Tag] = []) {
        self.tagsToReturn = tagsToReturn
    }

    func upsert(_ tag: Dropin.Tag) async throws {
        if shouldThrowOnUpsert { throw MockSyncError.intentional }
        upsertedTags.append(tag)
    }

    func fetch(updatedAfter date: Date) async throws -> [Dropin.Tag] {
        return tagsToReturn
    }
}
