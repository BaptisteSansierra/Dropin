//
//  DeletePlace.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/25.
//

import Foundation

@MainActor
struct DeletePlace {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }
    
    func execute(_ place: PlaceEntity) async throws {
        if try await !repository.exists(place) {
            throw DomainError.Place.notFound
        }
        return try await repository.delete(place)
    }
}
