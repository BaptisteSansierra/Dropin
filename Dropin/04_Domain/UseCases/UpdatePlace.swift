//
//  UpdatePlace.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/25.
//

import Foundation

@MainActor
struct UpdatePlace {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }
    
    func execute(_ place: PlaceEntity) async throws {
        guard place.name.count > 0 else {
            throw DomainError.Place.missingName
        }
        if try await !repository.exists(place) {
            throw DomainError.Place.notFound
        }
        return try await repository.update(place)
    }
}
