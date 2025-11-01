//
//  CreatePlace.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import CoreLocation

@MainActor
struct CreatePlace {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }

    func execute(_ place: PlaceEntity) async throws {
        guard place.name.count > 0 else {
            throw DomainError.Place.missingName
        }
        if try await repository.exists(place) {
            throw DomainError.Place.alreadyExists
        }
        try await repository.create(place)
    }
}
