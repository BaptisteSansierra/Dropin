//
//  MockRemotePlaceRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockRemotePlaceRepository: RemotePlaceRepository, @unchecked Sendable {
    private(set) var upsertedPlaces: [Place] = []
    var placesToReturn: [Place]
    var shouldThrowOnUpsert = false
    /// Keeps `upsert` in flight (cancellable sleep), to test cancellation mid-push
    var upsertDelay: Duration?
    private(set) var upsertStartedCount = 0

    init() {
        self.placesToReturn = []
    }

    init(placesToReturn: [Place] = []) {
        self.placesToReturn = placesToReturn
    }

    func upsert(_ place: Place) async throws {
        upsertStartedCount += 1
        if let upsertDelay { try await Task.sleep(for: upsertDelay) }
        if shouldThrowOnUpsert { throw MockSyncError.intentional }
        upsertedPlaces.append(place)
    }

    func fetch(updatedAfter date: Date, excludeDeleted: Bool) async throws -> [Place] {
        excludeDeleted ? placesToReturn.filter { $0.deletedAt == nil } : placesToReturn
    }
}
