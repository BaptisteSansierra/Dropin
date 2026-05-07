//
//  ImageRepositoryImpl.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import Foundation
import SwiftData

final class ImageRepositoryImpl: ImageRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func add(placeId: UUID, thumbnail: Data, full: Data) async throws -> UUID {
        let predicate = #Predicate<SDPlace> { $0.identifier == placeId }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        guard let sdPlace = try modelContext.fetch(descriptor).first else {
            throw DataError.notFound(msg: "couldn't find SDPlace with id \(placeId)")
        }
        let image = SDImage(thumbnail: thumbnail, full: full)
        modelContext.insert(image)
        sdPlace.images.append(image)
        try modelContext.save()
        return image.id
    }

    func remove(id: UUID) async throws {
        let predicate = #Predicate<SDImage> { $0.id == id }
        let descriptor = FetchDescriptor<SDImage>(predicate: predicate)
        guard let sdImage = try modelContext.fetch(descriptor).first else {
            throw DataError.notFound(msg: "couldn't find SDImage with id \(id)")
        }
        modelContext.delete(sdImage)
        try modelContext.save()
    }

    func fetchThumbnails(placeId: UUID) async throws -> [(id: UUID, thumbnail: Data)] {
        let predicate = #Predicate<SDPlace> { $0.identifier == placeId }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        guard let sdPlace = try modelContext.fetch(descriptor).first else {
            throw DataError.notFound(msg: "couldn't find SDPlace with id \(placeId)")
        }
        return sdPlace.images.map { ($0.id, $0.thumbnail) }
    }

    func fetchFull(id: UUID) async throws -> Data {
        let predicate = #Predicate<SDImage> { $0.id == id }
        let descriptor = FetchDescriptor<SDImage>(predicate: predicate)
        guard let sdImage = try modelContext.fetch(descriptor).first else {
            throw DataError.notFound(msg: "couldn't find SDImage with id \(id)")
        }
        return sdImage.full
    }
}
