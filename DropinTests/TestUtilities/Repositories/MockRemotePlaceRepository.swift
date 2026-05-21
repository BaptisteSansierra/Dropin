//
//  MockRemotePlaceRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockRemotePlaceRepository: RemotePlaceRepository, @unchecked Sendable {
    private(set) var upsertedPlaces: [PlaceEntity] = []
    var placesToReturn: [PlaceEntity]
    var shouldThrowOnUpsert = false

    init(placesToReturn: [PlaceEntity] = []) {
        self.placesToReturn = placesToReturn
    }

    func upsert(_ place: PlaceEntity) async throws {
        if shouldThrowOnUpsert { throw MockSyncError.intentional }
        upsertedPlaces.append(place)
    }

    func fetch(updatedAfter date: Date) async throws -> [PlaceEntity] {
        return placesToReturn
    }
}
