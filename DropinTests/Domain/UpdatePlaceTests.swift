//
//  UpdatePlaceTests.swift
//  DropinTests
//

import Testing
import Foundation
@testable import Dropin

@MainActor
struct UpdatePlaceTests {

    @Test func throwsMissingNameForEmptyName() async throws {
        let repo = MockPlaceRepository()
        let sut = UpdatePlace(repository: repo)
        let place = Place(id: UUID(), name: "", coordinates: .barcelona, address: "")
        await #expect(throws: DomainError.Place.missingName, performing: {
            try await sut(place)
        })
    }

    @Test func throwsNotFoundWhenPlaceDoesNotExist() async throws {
        let repo = MockPlaceRepository()
        let sut = UpdatePlace(repository: repo)
        let place = Place(id: UUID(), name: "Ghost Place", coordinates: .barcelona, address: "")
        await #expect(throws: DomainError.Place.notFound, performing: {
            try await sut(place)
        })
    }

    @Test func updatesExistingPlace() async throws {
        let original = Place(id: UUID(), name: "Original Name", coordinates: .barcelona, address: "")
        let repo = MockPlaceRepository(initialPlaces: [original])
        let sut = UpdatePlace(repository: repo)

        let edited = Place(id: original.id, name: "Renamed", coordinates: original.coordinates, address: "")
        try await sut(edited)

        let stored = try await repo.fetch(original.id)
        #expect(stored.name == "Renamed")
    }
}
