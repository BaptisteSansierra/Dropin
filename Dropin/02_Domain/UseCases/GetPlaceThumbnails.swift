//
//  GetPlaceThumbnails.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import Foundation

@MainActor
struct GetPlaceThumbnails {
    private let repository: ImageRepository

    init(repository: ImageRepository) {
        self.repository = repository
    }

    func callAsFunction(placeId: UUID) async throws -> [(id: UUID, thumbnail: Data)] {
        return try await repository.fetchThumbnails(placeId: placeId)
    }
}
