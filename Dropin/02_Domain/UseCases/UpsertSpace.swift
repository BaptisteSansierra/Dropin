//
//  UpsertSpace.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/10/26.
//

import Foundation

@MainActor
struct UpsertSpace {
    private let repository: SpaceRepository
    
    init(repository: SpaceRepository) {
        self.repository = repository
    }
    
    func callAsFunction(_ space: Space, shouldSave: Bool = true) async throws {
        try await repository.upsert(space, shouldSave: shouldSave)
    }
}
