//
//  AddPlaceImage.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import UIKit

@MainActor
struct AddPlaceImage {
    private let repository: ImageRepository

    init(repository: ImageRepository) {
        self.repository = repository
    }

    func callAsFunction(placeId: UUID, image: UIImage) async throws -> UUID {
        guard let fullData = image.compressedForStorage() else {
            throw DomainError.Image.invalidData
        }
        guard let thumbnailData = image.thumbnailData() else {
            throw DomainError.Image.invalidData
        }
        return try await repository.add(placeId: placeId, thumbnail: thumbnailData, full: fullData)
    }
}
