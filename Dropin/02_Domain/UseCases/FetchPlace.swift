//
//  FetchPlaces.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/4/26.
//


import Foundation

@MainActor
struct FetchPlace: Sendable {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ uuid: UUID) async throws -> PlaceEntity {
        return try await repository.fetch(uuid)
    }
}
