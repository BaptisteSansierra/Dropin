//
//  FetchGroupsWithCount.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/4/26.
//

import Foundation

@MainActor
struct FetchGroupsWithCount {
    private let repository: GroupRepository
    
    init(repository: GroupRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> [(GroupEntity, Int)] {
        return try await repository.fetchWithPlaceCount()
    }
}

