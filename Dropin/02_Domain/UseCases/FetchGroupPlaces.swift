//
//  FetchGroupPlaces.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/4/26.
//

import Foundation

@MainActor
struct FetchGroupPlaces: Sendable {
    private let repository: PlaceRepository
    
    init(repository: PlaceRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ groupId: UUID) async throws -> [PlaceEntity] {
        return try await repository.fetch(groupId: groupId)
    }
}
