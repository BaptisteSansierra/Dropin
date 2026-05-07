//
//  RemovePlaceImage.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import Foundation

@MainActor
struct RemovePlaceImage {
    private let repository: ImageRepository

    init(repository: ImageRepository) {
        self.repository = repository
    }

    func callAsFunction(id: UUID) async throws {
        try await repository.remove(id: id)
    }
}
