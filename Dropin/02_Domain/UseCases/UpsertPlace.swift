//
//  UpsertPlace.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/4/26.
//

import Foundation

@MainActor
struct UpsertPlace {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ place: PlaceEntity, shouldSave: Bool = true) async throws {
        guard !place.name.isEmpty else {
            throw DomainError.Place.missingName
        }
        try await repository.upsert(place, shouldSave: shouldSave)
    }
}
