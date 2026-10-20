//
//  App_SyncingPlaceRepository.swift
//  DropinTests
//

import Testing
import Foundation
@testable import Dropin

@MainActor
struct AppSyncing_PlaceRepository {

    /// Minimal spy: deliberately not the real SyncService. SyncingPlaceRepository
    /// only needs to prove it *calls* markPlaceDirty; SyncService's own
    /// pendingChangeCount bookkeeping (which also factors in in-flight push
    /// tasks) is covered by SyncServiceTests and would just make this test
    /// flaky/coupled to unrelated behavior.
    private final class SyncServiceSpy: SyncServiceProtocol {
        var syncStatus = SyncStatus()
        var pendingChangeCount: Int = 0
        private(set) var dirtyPlaceIds: [UUID] = []

        func markPlaceDirty(_ id: UUID) { dirtyPlaceIds.append(id) }
        func markCategoryDirty(_ id: UUID) {}
        func markTagDirty(_ id: UUID) {}
        func markSpaceDirty(_ id: UUID) {}
        func markImagesChanged() {}
        func markProfileDirty() {}
        func syncAll() async {}
        func reset() {}
    }

    // Regression: UpdatePlace used to be suspected of needing to stamp updatedAt
    // itself. It doesn't — this decorator is the one actually responsible, and
    // must keep doing so regardless of what the caller passes in.
    @Test func updateStampsFreshUpdatedAtRegardlessOfCallerValue() async throws {
        let original = Place(id: UUID(), name: "Test Place", coordinates: .barcelona, address: "")
        let local = MockPlaceRepository(initialPlaces: [original])
        let sut = SyncingPlaceRepository(wrapped: local, sync: SyncServiceSpy())

        // Caller passes a place whose updatedAt is whatever it was before editing.
        let callerPlace = Place(id: original.id, name: "Updated Name", coordinates: original.coordinates, address: "")
        try await sut.update(callerPlace)

        let stored = try await local.fetch(original.id)
        #expect(stored.name == "Updated Name")
        #expect(stored.updatedAt > callerPlace.updatedAt)
    }

    @Test func updateMarksPlaceDirty() async throws {
        let original = Place(id: UUID(), name: "Test Place", coordinates: .barcelona, address: "")
        let local = MockPlaceRepository(initialPlaces: [original])
        let spy = SyncServiceSpy()
        let sut = SyncingPlaceRepository(wrapped: local, sync: spy)

        try await sut.update(original)

        #expect(spy.dirtyPlaceIds == [original.id])
    }

    @Test func upsertAlsoStampsFreshUpdatedAt() async throws {
        let original = Place(id: UUID(), name: "Test Place", coordinates: .barcelona, address: "")
        let local = MockPlaceRepository(initialPlaces: [original])
        let sut = SyncingPlaceRepository(wrapped: local, sync: SyncServiceSpy())

        try await sut.upsert(original, shouldSave: true)

        let stored = try await local.fetch(original.id)
        #expect(stored.updatedAt > original.updatedAt)
    }

    @Test func upsertAlsoMarksPlaceDirty() async throws {
        let original = Place(id: UUID(), name: "Test Place", coordinates: .barcelona, address: "")
        let local = MockPlaceRepository(initialPlaces: [original])
        let spy = SyncServiceSpy()
        let sut = SyncingPlaceRepository(wrapped: local, sync: spy)

        try await sut.upsert(original, shouldSave: true)

        #expect(spy.dirtyPlaceIds == [original.id])
    }
}
