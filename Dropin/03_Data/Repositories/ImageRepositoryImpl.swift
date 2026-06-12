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

    /// Soft-delete unless never pushed; SyncService finalizes synced ones with hardDelete.
    func remove(id: UUID) async throws {
        let predicate = #Predicate<SDImage> { $0.id == id }
        let descriptor = FetchDescriptor<SDImage>(predicate: predicate)
        guard let sdImage = try modelContext.fetch(descriptor).first else {
            throw DataError.notFound(msg: "couldn't find SDImage with id \(id)")
        }
        if sdImage.syncedAt == nil {
            modelContext.delete(sdImage)
        } else {
            sdImage.deletedAt = Date()
        }
        try modelContext.save()
    }

    func fetchThumbnails(placeId: UUID) async throws -> [(id: UUID, thumbnail: Data?)] {
        let predicate = #Predicate<SDPlace> { $0.identifier == placeId }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        guard let sdPlace = try modelContext.fetch(descriptor).first else {
            throw DataError.notFound(msg: "couldn't find SDPlace with id \(placeId)")
        }
        return sdPlace.images
            .filter { $0.deletedAt == nil }
            .map { ($0.id, $0.thumbnail) }
    }

    func fetchFull(id: UUID) async throws -> Data? {
        let predicate = #Predicate<SDImage> { $0.id == id && $0.deletedAt == nil }
        let descriptor = FetchDescriptor<SDImage>(predicate: predicate)
        return try modelContext.fetch(descriptor).first?.full
    }

    func fetchPlaceId(imageId: UUID) async throws -> UUID? {
        let predicate = #Predicate<SDImage> { $0.id == imageId }
        let descriptor = FetchDescriptor<SDImage>(predicate: predicate)
        return try modelContext.fetch(descriptor).first?.place?.identifier
    }

    func cacheThumbnail(id: UUID, data: Data) async throws {
        let predicate = #Predicate<SDImage> { $0.id == id }
        let descriptor = FetchDescriptor<SDImage>(predicate: predicate)
        guard let sd = try modelContext.fetch(descriptor).first else { return }
        sd.thumbnail = data
        try modelContext.save()
    }

    func cacheFull(id: UUID, data: Data) async throws {
        let predicate = #Predicate<SDImage> { $0.id == id }
        let descriptor = FetchDescriptor<SDImage>(predicate: predicate)
        guard let sd = try modelContext.fetch(descriptor).first else { return }
        sd.full = data
        try modelContext.save()
    }
    
    func clearTable() async throws {
        try modelContext.delete(model: SDImage.self)
        try modelContext.save()
    }

    // MARK: - Sync-facing

    func fetchUnsynced() async throws -> [ImageRef] {
        let predicate = #Predicate<SDImage> { $0.syncedAt == nil && $0.deletedAt == nil }
        let descriptor = FetchDescriptor<SDImage>(predicate: predicate)
        return try modelContext.fetch(descriptor).compactMap { sd in
            guard let placeId = sd.place?.identifier,
                  let thumb = sd.thumbnail,
                  let full = sd.full else { return nil }
            return ImageRef(id: sd.id, placeId: placeId, thumbnail: thumb, full: full)
        }
    }

    func fetchPendingDelete() async throws -> [(id: UUID, placeId: UUID)] {
        let predicate = #Predicate<SDImage> { $0.deletedAt != nil }
        let descriptor = FetchDescriptor<SDImage>(predicate: predicate)
        return try modelContext.fetch(descriptor).compactMap { sd in
            guard let placeId = sd.place?.identifier else { return nil }
            return (sd.id, placeId)
        }
    }

    func markSynced(id: UUID) async throws {
        let predicate = #Predicate<SDImage> { $0.id == id }
        let descriptor = FetchDescriptor<SDImage>(predicate: predicate)
        guard let sd = try modelContext.fetch(descriptor).first else { return }
        sd.syncedAt = Date()
        try modelContext.save()
    }

    func hardDelete(id: UUID) async throws {
        let predicate = #Predicate<SDImage> { $0.id == id }
        let descriptor = FetchDescriptor<SDImage>(predicate: predicate)
        guard let sd = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(sd)
        try modelContext.save()
    }

    func insertSynced(id: UUID, placeId: UUID) async throws {
        let predicate = #Predicate<SDPlace> { $0.identifier == placeId }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        guard let sdPlace = try modelContext.fetch(descriptor).first else {
            throw DataError.notFound(msg: "couldn't find SDPlace with id \(placeId)")
        }
        let image = SDImage(id: id)
        image.syncedAt = Date()
        modelContext.insert(image)
        sdPlace.images.append(image)
        try modelContext.save()
    }

    func localImageIds(placeId: UUID) async throws -> Set<UUID> {
        let predicate = #Predicate<SDPlace> { $0.identifier == placeId }
        let descriptor = FetchDescriptor<SDPlace>(predicate: predicate)
        guard let sdPlace = try modelContext.fetch(descriptor).first else { return [] }
        return Set(sdPlace.images.map { $0.id })
    }
}
