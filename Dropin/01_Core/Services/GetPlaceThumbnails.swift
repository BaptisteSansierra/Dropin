//
//  GetPlaceThumbnails.swift
//  Dropin
//
//  Thin proxy over ImageLoader so VMs don't depend on the actor directly.
//

import Foundation

@MainActor
struct GetPlaceThumbnails {
    private let loader: ImageLoader

    init(loader: ImageLoader) {
        self.loader = loader
    }

    /// Initial state snapshot. Downloads are kicked off automatically; call
    /// `awaitThumbnail(...)` per `.downloading` entry to observe completion.
    func callAsFunction(placeId: UUID) async throws -> [(id: UUID, state: ImageLoadState)] {
        try await loader.thumbnails(for: placeId)
    }

    func awaitThumbnail(imageId: UUID, placeId: UUID) async -> ImageLoadState {
        await loader.awaitThumbnail(imageId: imageId, placeId: placeId)
    }
}
