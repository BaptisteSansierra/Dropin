//
//  GetPlaceImage.swift
//  Dropin
//
//  Thin proxy over PlaceImageLoader so VMs don't depend on the actor directly.
//

import Foundation

@MainActor
struct GetPlaceImage {
    private let loader: PlaceImageLoader

    init(loader: PlaceImageLoader) {
        self.loader = loader
    }

    /// Returns state and triggers a download if not already cached / failed / in-flight.
    func callAsFunction(id: UUID, placeId: UUID) async -> ImageLoadState {
        await loader.full(imageId: id, placeId: placeId)
    }
}
