//
//  AddressBackfillingPlaceRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 25/9/26.
//

import Foundation

///  Decorates the place repository's read path so every screen that fetches places gets address backfill for free
@MainActor
final class AddressBackfillingPlaceRepository: PlaceRepository {
    private let wrapped: any PlaceRepository
    private let backfillService: any AddressBackfillServiceProtocol

    init(wrapped: any PlaceRepository, backfillService: any AddressBackfillServiceProtocol) {
        self.wrapped = wrapped
        self.backfillService = backfillService
    }

    func exists(_ place: Place) async throws -> Bool { try await wrapped.exists(place) }
    func create(_ place: Place) async throws { try await wrapped.create(place) }
    func update(_ place: Place) async throws { try await wrapped.update(place) }
    func upsert(_ place: Place, shouldSave: Bool) async throws { try await wrapped.upsert(place, shouldSave: shouldSave) }
    func clearTable() async throws { try await wrapped.clearTable() }

    func fetch(_ id: UUID) async throws -> Place {
        let place = try await wrapped.fetch(id)
        backfillService.backfillIfNeeded(place)
        return place
    }

    func fetch(categoryId: UUID) async throws -> [Place] {
        let places = try await wrapped.fetch(categoryId: categoryId)
        places.forEach { backfillService.backfillIfNeeded($0) }
        return places
    }

    func fetch(tagId: UUID) async throws -> [Place] {
        let places = try await wrapped.fetch(tagId: tagId)
        places.forEach { backfillService.backfillIfNeeded($0) }
        return places
    }

    func fetch() async throws -> [Place] {
        let places = try await wrapped.fetch()
        places.forEach { backfillService.backfillIfNeeded($0) }
        return places
    }

    func fetch(_ filter: PlaceFilter?) async throws -> [Place] {
        let places = try await wrapped.fetch(filter)
        places.forEach { backfillService.backfillIfNeeded($0) }
        return places
    }
}
