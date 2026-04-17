//
//  FetchTagsWithCount.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/4/26.
//

import Foundation

@MainActor
struct FetchTagsWithCount {
    private let repository: TagRepository
    
    init(repository: TagRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> [(TagEntity, Int)] {
        return try await repository.fetchWithPlaceCount()
    }
}
