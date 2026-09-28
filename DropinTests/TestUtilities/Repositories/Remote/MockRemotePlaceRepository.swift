//
//  MockRemotePlaceRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockRemotePlaceRepository: RemotePlaceRepository, @unchecked Sendable {
    private(set) var upsertedPlaces: [Place] = []
    var placesToReturn: [Place]
    var shouldThrowOnUpsert = false

    init(placesToReturn: [Place] = []) {
        self.placesToReturn = placesToReturn
    }

    func upsert(_ place: Place) async throws {
        if shouldThrowOnUpsert { throw MockSyncError.intentional }
        upsertedPlaces.append(place)
    }

    func fetch(updatedAfter date: Date) async throws -> [Place] {
        return placesToReturn
    }
}
