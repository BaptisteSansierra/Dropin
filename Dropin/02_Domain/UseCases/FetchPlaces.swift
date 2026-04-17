//
//  FetchPlaces.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation

@MainActor
struct FetchPlaces: Sendable {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }
    
    func execute(_ filter: PlaceFilter? = nil) async throws -> [PlaceEntity] {
        return try await repository.fetch(filter)
    }
}
