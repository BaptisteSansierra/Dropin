//
//  MockImageRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

@MainActor
final class MockImageRepository: ImageRepository {
    struct Stored {
        var id: UUID
        var placeId: UUID
        var thumbnail: Data?
        var full: Data?
        var syncedAt: Date?
        var deletedAt: Date?
    }

    private(set) var items: [Stored] = []

    init(initial: [Stored] = []) {
        self.items = initial
    }

    func add(placeId: UUID, thumbnail: Data, full: Data) async throws -> UUID {
        let id = UUID()
        items.append(Stored(id: id, placeId: placeId, thumbnail: thumbnail, full: full,
                            syncedAt: nil, deletedAt: nil))
        return id
    }

    func remove(id: UUID) async throws {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        if items[idx].syncedAt == nil {
            items.remove(at: idx)
        } else {
            items[idx].deletedAt = Date()
        }
    }

    func fetchThumbnails(placeId: UUID) async throws -> [(id: UUID, thumbnail: Data?)] {
        items.filter { $0.placeId == placeId && $0.deletedAt == nil }
             .map { ($0.id, $0.thumbnail) }
    }

    func fetchFull(id: UUID) async throws -> Data? {
        items.first(where: { $0.id == id && $0.deletedAt == nil })?.full
    }

    func fetchPlaceId(imageId: UUID) async throws -> UUID? {
        items.first(where: { $0.id == imageId })?.placeId
    }

    func cacheThumbnail(id: UUID, data: Data) async throws {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].thumbnail = data
    }

    func cacheFull(id: UUID, data: Data) async throws {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].full = data
    }

    func fetchUnsynced() async throws -> [ImageRef] {
        items.compactMap { item in
            guard item.syncedAt == nil, item.deletedAt == nil,
                  let thumb = item.thumbnail, let full = item.full else { return nil }
            return ImageRef(id: item.id, placeId: item.placeId, thumbnail: thumb, full: full)
        }
    }

    func fetchPendingDelete() async throws -> [(id: UUID, placeId: UUID)] {
        items.filter { $0.deletedAt != nil }.map { ($0.id, $0.placeId) }
    }

    func markSynced(id: UUID) async throws {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].syncedAt = Date()
    }

    func hardDelete(id: UUID) async throws {
        items.removeAll { $0.id == id }
    }

    func insertSynced(id: UUID, placeId: UUID) async throws {
        items.append(Stored(id: id, placeId: placeId, thumbnail: nil, full: nil,
                            syncedAt: Date(), deletedAt: nil))
    }

    func localImageIds(placeId: UUID) async throws -> Set<UUID> {
        Set(items.filter { $0.placeId == placeId }.map { $0.id })
    }
}
