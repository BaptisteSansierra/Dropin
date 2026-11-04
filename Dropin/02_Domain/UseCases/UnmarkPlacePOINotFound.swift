//
//  UnmarkPlacePOINotFound.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

import Foundation

@MainActor
struct UnmarkPlacePOINotFound {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }
    
    func callAsFunction(uuid: UUID) async throws {
        let place = try await repository.fetch(uuid)
        guard let _ = place.appleNotFoundAt else { return }
        let updatedPlace = place.withAppleNotFoundAt(notFoundAt: nil)
        return try await repository.update(updatedPlace)
    }
}
