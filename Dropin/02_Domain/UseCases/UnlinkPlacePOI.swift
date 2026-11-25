//
//  UnlinkPlacePOI.swift
//  Dropin
//
//  Created by baptiste sansierra on 8/10/26.
//

import Foundation

@MainActor
struct UnlinkPlacePOI {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }
    
    func callAsFunction(uuid: UUID) async throws {
        let place = try await repository.fetch(uuid)
        guard let _ = place.applePlaceID else {
            // nothing to do
            return
        }
        // Note: do not reset attribute appleNotFoundAt
        //   so we can keep a trace the place was historicaly linked to Apple
        //   Maybe that's useless but who knows...
        let updatedPlace = place.withUnlinkedPOI()
        return try await repository.update(updatedPlace)
    }
}
