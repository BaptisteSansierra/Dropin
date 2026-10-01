//
//  SyncingRepositories.swift
//  Dropin
//
//  Repository decorators that notify SyncService after each mutation.
//  Reads pass through unchanged. Mutations: write to local first, then
//  mark dirty so the push queue picks the change up.
//

import Foundation

@MainActor
final class SyncingPlaceRepository: PlaceRepository {
    private let wrapped: any PlaceRepository
    private let sync: any SyncServiceProtocol

    init(wrapped: any PlaceRepository, sync: any SyncServiceProtocol) {
        self.wrapped = wrapped
        self.sync = sync
    }

    func exists(_ place: Place) async throws -> Bool { try await wrapped.exists(place) }
    func fetch(_ id: UUID) async throws -> Place { try await wrapped.fetch(id) }
    func fetch(categoryId: UUID) async throws -> [Place] { try await wrapped.fetch(categoryId: categoryId) }
    func fetch(tagId: UUID) async throws -> [Place] { try await wrapped.fetch(tagId: tagId) }
    func fetch() async throws -> [Place] { try await wrapped.fetch() }
    func fetch(_ filter: PlaceFilter?) async throws -> [Place] { try await wrapped.fetch(filter) }

    func create(_ place: Place) async throws {
        try await wrapped.create(place)
        sync.markPlaceDirty(place.id)
    }

    func update(_ place: Place) async throws {
        let stamped = place.updated()
        try await wrapped.update(stamped)
        sync.markPlaceDirty(stamped.id)
    }

    /*
    func delete(_ place: Place) async throws {
        try await wrapped.delete(place)
        sync.markPlaceDirty(place.id)
    }
     */

    func upsert(_ place: Place, shouldSave: Bool) async throws {
        let stamped = place.updated()
        try await wrapped.upsert(stamped, shouldSave: shouldSave)
        sync.markPlaceDirty(stamped.id)
    }

    func clearTable() async throws {
        try await wrapped.clearTable()
        // local-only: intentionally NOT calling sync.markDirty
    }
}

@MainActor
final class SyncingCategoryRepository: CategoryRepository {
    private let wrapped: any CategoryRepository
    private let sync: any SyncServiceProtocol
    
    init(wrapped: any CategoryRepository, sync: any SyncServiceProtocol) {
        self.wrapped = wrapped
        self.sync = sync
    }
    
    func exists(_ category: Category) async throws -> Bool { try await wrapped.exists(category) }
    func fetch() async throws -> [Category] { try await wrapped.fetch() }
    func fetchWithPlaceCount() async throws -> [(Category, Int)] { try await wrapped.fetchWithPlaceCount() }
    func fetch(_ id: UUID) async throws -> Category { try await wrapped.fetch(id) }
    
    func create(_ category: Category) async throws {
        try await wrapped.create(category)
        sync.markCategoryDirty(category.id)
    }
    
    func update(_ category: Category) async throws {
        let stamped = category.updated()
        try await wrapped.update(stamped)
        sync.markCategoryDirty(stamped.id)
    }
    
    /*
    func delete(_ category: Category) async throws {
        try await wrapped.delete(category)
        sync.markCategoryDirty(category.id)
    }
     */
    
    func upsert(_ category: Category, shouldSave: Bool) async throws {
        let stamped = category.updated()
        try await wrapped.upsert(stamped, shouldSave: shouldSave)
        sync.markCategoryDirty(stamped.id)
    }
    
    func clearTable() async throws {
        try await wrapped.clearTable()
        // local-only: intentionally NOT calling sync.markDirty
    }
}

@MainActor
final class SyncingProfileRepository: ProfileRepository {
    private let wrapped: any ProfileRepository
    private let sync: any SyncServiceProtocol
    
    init(wrapped: any ProfileRepository, sync: any SyncServiceProtocol) {
        self.wrapped = wrapped
        self.sync = sync
    }
    
    func fetch() async throws -> Profile? {
        try await wrapped.fetch()
    }
    
    /// Passthrough: `upsert` is also used by ProfileService when seeding the
    /// cache from a remote fetch — we must NOT mark dirty there, or we'd echo
    /// the just-pulled data back to the server. User-initiated edits go through
    /// `update(displayName:)` which is the only path that marks dirty.
    func upsert(_ profile: Profile) async throws {
        try await wrapped.upsert(profile)
    }
    
    func update(displayName: String?) async throws -> Profile {
        let updated = try await wrapped.update(displayName: displayName)
        sync.markProfileDirty()
        return updated
    }
    
    func clearTable() async throws {
        try await wrapped.clearTable()
        // local-only: intentionally NOT calling sync.markDirty
    }
}

@MainActor
final class SyncingPlaceImageRepository: PlaceImageRepository {
    private let wrapped: any PlaceImageRepository
    private let sync: any SyncServiceProtocol
    
    init(wrapped: any PlaceImageRepository, sync: any SyncServiceProtocol) {
        self.wrapped = wrapped
        self.sync = sync
    }
    
    func add(placeId: UUID, thumbnail: Data, full: Data) async throws -> UUID {
        let id = try await wrapped.add(placeId: placeId, thumbnail: thumbnail, full: full)
        sync.markImagesChanged()
        return id
    }
    
    func remove(id: UUID) async throws {
        try await wrapped.remove(id: id)
        sync.markImagesChanged()
    }
    
    func fetchThumbnails(placeId: UUID) async throws -> [(id: UUID, thumbnail: Data?)] {
        try await wrapped.fetchThumbnails(placeId: placeId)
    }
    
    func fetchFull(id: UUID) async throws -> Data? {
        try await wrapped.fetchFull(id: id)
    }
    
    func fetchPlaceId(imageId: UUID) async throws -> UUID? {
        try await wrapped.fetchPlaceId(imageId: imageId)
    }
    
    func cacheThumbnail(id: UUID, data: Data) async throws { try await wrapped.cacheThumbnail(id: id, data: data) }
    func cacheFull(id: UUID, data: Data) async throws { try await wrapped.cacheFull(id: id, data: data) }
    
    // Sync-facing — pass through, no further notification needed.
    func fetchUnsynced() async throws -> [PlaceImageRef] { try await wrapped.fetchUnsynced() }
    func fetchPendingDelete() async throws -> [(id: UUID, placeId: UUID)] { try await wrapped.fetchPendingDelete() }
    func markSynced(id: UUID) async throws { try await wrapped.markSynced(id: id) }
    func hardDelete(id: UUID) async throws { try await wrapped.hardDelete(id: id) }
    func insertSynced(id: UUID, placeId: UUID) async throws {
        try await wrapped.insertSynced(id: id, placeId: placeId)
    }
    func localImageIds(placeId: UUID) async throws -> Set<UUID> { try await wrapped.localImageIds(placeId: placeId) }
    
    func clearTable() async throws {
        try await wrapped.clearTable()
        // local-only: intentionally NOT calling sync.markDirty
    }
}

@MainActor
final class SyncingTagRepository: TagRepository {
    private let wrapped: any TagRepository
    private let sync: any SyncServiceProtocol
    
    init(wrapped: any TagRepository, sync: any SyncServiceProtocol) {
        self.wrapped = wrapped
        self.sync = sync
    }
    
    func exists(_ tag: Tag) async throws -> Bool { try await wrapped.exists(tag) }
    func fetch() async throws -> [Tag] { try await wrapped.fetch() }
    func fetchWithPlaceCount() async throws -> [(Tag, Int)] { try await wrapped.fetchWithPlaceCount() }
    func fetch(_ id: UUID) async throws -> Tag { try await wrapped.fetch(id) }
    
    func create(_ tag: Tag) async throws {
        try await wrapped.create(tag)
        sync.markTagDirty(tag.id)
    }
    
    func update(_ tag: Tag) async throws {
        let stamped = tag.updated()
        try await wrapped.update(stamped)
        sync.markTagDirty(stamped.id)
    }
    
    /*
    func delete(_ tag: Tag) async throws {
        try await wrapped.delete(tag)
        sync.markTagDirty(tag.id)
    }
     */
    
    func upsert(_ tag: Tag, shouldSave: Bool) async throws {
        let stamped = tag.updated()
        try await wrapped.upsert(stamped, shouldSave: shouldSave)
        sync.markTagDirty(stamped.id)
    }
    
    func clearTable() async throws {
        try await wrapped.clearTable()
        // local-only: intentionally NOT calling sync.markDirty
    }
}
