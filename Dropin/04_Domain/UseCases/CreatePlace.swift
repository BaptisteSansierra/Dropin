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
        return try await repository.create(place)
    }

//    func execute(coordinates: CLLocationCoordinate2D) async throws {
//        let place = PlaceEntity(coordinates: coordinates)
//        return try await repository.create(place)
//    }
}
