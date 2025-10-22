//
//  GetPlaces.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation

@MainActor
struct GetPlaces: Sendable {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> [PlaceEntity] {
        return try await repository.getAll()
    }
}
