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
        return try await repository.update(place)
    }
}
