//
//  UpsertPlaceInSpace.swift
//  Dropin
//

import Foundation

/// Used by SyncService.pull, where the incoming place's own spaceId (from the remote DTO)
/// must be used on insert rather than SpaceContext.currentSpaceId, as the pulled entity may
/// belong to a space other than the one currently active on this device.
@MainActor
struct UpsertPlaceInSpace {
    private let repository: PlaceRepository

    init(repository: PlaceRepository) {
        self.repository = repository
    }

    func callAsFunction(_ place: Place, spaceId: UUID, shouldSave: Bool = true) async throws {
        guard !place.name.isEmpty else {
            throw DomainError.Place.missingName
        }
        try await repository.upsert(place, spaceId: spaceId, shouldSave: shouldSave)
    }
}
