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
        guard let fullData = compressForStorage(image) else {
            throw DomainError.Image.invalidData
        }
        let thumbnailSize = CGSize(square: DropinApp.storage.thumbnailSize)
        let thumbnailImage = image.preparingThumbnail(of: thumbnailSize) ?? image
        guard let thumbnailData = thumbnailImage.jpegData(compressionQuality: DropinApp.storage.thumbnailCompression) else {
            throw DomainError.Image.invalidData
        }
        return try await repository.add(placeId: placeId, thumbnail: thumbnailData, full: fullData)
    }

    private func compressForStorage(_ image: UIImage) -> Data? {
        let resized = resize(image, maxDimension: DropinApp.storage.imageMaxSize)
        for quality: CGFloat in [0.8, 0.65, 0.5, 0.35] {
            guard let data = resized.jpegData(compressionQuality: quality) else { continue }
            if data.count <= DropinApp.storage.imageMaxDiskSize { return data }
        }
        return resized.jpegData(compressionQuality: 0.35)
    }

    private func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return image }
        let scale = maxDimension / longestSide
        let newSize = CGSize(width: (size.width * scale).rounded(),
                             height: (size.height * scale).rounded())
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
