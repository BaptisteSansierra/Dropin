//
//  GetPlaceImage.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import Foundation

@MainActor
struct GetPlaceImage {
    private let repository: ImageRepository

    init(repository: ImageRepository) {
        self.repository = repository
    }

    func callAsFunction(id: UUID) async throws -> Data {
        return try await repository.fetchFull(id: id)
    }
}
