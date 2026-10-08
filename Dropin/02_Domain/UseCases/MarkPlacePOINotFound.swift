//
//  MarkPlacePOINotFound.swift
//  Dropin
//
//  Created by baptiste sansierra on 8/10/26.
//

import Foundation

@MainActor
struct MarkPlacePOINotFound {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }
    
    func callAsFunction(uuid: UUID, date: Date) async throws {
        let place = try await repository.fetch(uuid)
        if place.applePlaceID != nil {
            // This place was already marked previously
            // we want to keep the date of the first 'not found' occurence
            return
        }
        let updatedPlace = place.withAppleNotFoundAt(notFoundAt: date)
        return try await repository.update(updatedPlace)
    }
}
