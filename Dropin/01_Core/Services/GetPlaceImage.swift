//
//  GetPlaceImage.swift
//  Dropin
//
//  Thin proxy over ImageLoader so VMs don't depend on the actor directly.
//

import Foundation

@MainActor
struct GetPlaceImage {
    private let loader: ImageLoader

    init(loader: ImageLoader) {
        self.loader = loader
    }

    /// Returns state and triggers a download if not already cached / failed / in-flight.
    func callAsFunction(id: UUID, placeId: UUID) async -> ImageLoadState {
        await loader.full(imageId: id, placeId: placeId)
    }
}
