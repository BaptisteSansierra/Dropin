//
//  App_SyncingSpaceRepository.swift
//  DropinTests
//

import Testing
import Foundation
@testable import Dropin

@MainActor
struct AppSyncing_SpaceRepository {

    /// Minimal spy: deliberately not the real SyncService. See App_SyncingPlaceRepository
    /// for why — SyncingSpaceRepository only needs to prove it *calls* markSpaceDirty.
    private final class SyncServiceSpy: SyncServiceProtocol {
        var syncStatus = SyncStatus()
        var pendingChangeCount: Int = 0
        private(set) var dirtySpaceIds: [UUID] = []

        func markPlaceDirty(_ id: UUID) {}
        func markCategoryDirty(_ id: UUID) {}
        func markTagDirty(_ id: UUID) {}
        func markSpaceDirty(_ id: UUID) { dirtySpaceIds.append(id) }
        func markImagesChanged() {}
        func markProfileDirty() {}
        func syncAll() async {}
        func reset() {}
    }

    private func makeSpace() -> Space {
        Space(id: UUID(), name: "Secondary", color: "588B8B", icon: .sf("house"),
             ownerId: UUID(), createdAt: Date(), updatedAt: Date(), deletedAt: nil)
    }

    @Test func updateStampsFreshUpdatedAtRegardlessOfCallerValue() async throws {
        let original = makeSpace()
        let local = MockSpaceRepository(initialSpaces: [original])
        let sut = SyncingSpaceRepository(wrapped: local, sync: SyncServiceSpy())

        let callerSpace = Space(id: original.id, name: "Renamed", color: original.color, icon: original.icon,
                                ownerId: original.ownerId,
                                createdAt: original.createdAt, updatedAt: original.updatedAt, deletedAt: nil)
        try await sut.update(callerSpace)

        let stored = try await local.fetch(original.id)
        #expect(stored.name == "Renamed")
        #expect(stored.updatedAt > callerSpace.updatedAt)
    }

    @Test func updateMarksSpaceDirty() async throws {
        let original = makeSpace()
        let local = MockSpaceRepository(initialSpaces: [original])
        let spy = SyncServiceSpy()
        let sut = SyncingSpaceRepository(wrapped: local, sync: spy)

        try await sut.update(original)

        #expect(spy.dirtySpaceIds == [original.id])
    }

    @Test func upsertAlsoStampsFreshUpdatedAt() async throws {
        let original = makeSpace()
        let local = MockSpaceRepository(initialSpaces: [original])
        let sut = SyncingSpaceRepository(wrapped: local, sync: SyncServiceSpy())

        try await sut.upsert(original, shouldSave: true)

        let stored = try await local.fetch(original.id)
        #expect(stored.updatedAt > original.updatedAt)
    }

    @Test func upsertAlsoMarksSpaceDirty() async throws {
        let original = makeSpace()
        let local = MockSpaceRepository(initialSpaces: [original])
        let spy = SyncServiceSpy()
        let sut = SyncingSpaceRepository(wrapped: local, sync: spy)

        try await sut.upsert(original, shouldSave: true)

        #expect(spy.dirtySpaceIds == [original.id])
    }

    @Test func createMarksSpaceDirty() async throws {
        let local = MockSpaceRepository()
        let spy = SyncServiceSpy()
        let sut = SyncingSpaceRepository(wrapped: local, sync: spy)
        let space = makeSpace()

        try await sut.create(space)

        #expect(spy.dirtySpaceIds == [space.id])
    }
}
