//
//  DeletePlace.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/25.
//

import Foundation

// Hard delete not currently used
/*
@MainActor
struct DeletePlace {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ place: PlaceEntity) async throws {
        if try await !repository.exists(place) {
            throw DomainError.Place.notFound
        }
        return try await repository.delete(place)
    }
}
*/
