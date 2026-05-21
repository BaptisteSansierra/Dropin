//
//  MockRemoteImageRepository.swift
//  DropinTests

import Foundation
@testable import Dropin

final class MockRemoteImageRepository: RemoteImageRepository, @unchecked Sendable {
    struct Stored {
        var id: UUID
        var placeId: UUID
        var thumbnail: Data
        var full: Data
        var createdAt: Date
    }

    private(set) var uploaded: [Stored] = []
    private(set) var deleted: [(id: UUID, placeId: UUID)] = []
    var imagesToReturn: [Stored]
    var shouldThrowOnUpload = false
    var shouldThrowOnDelete = false

    init(imagesToReturn: [Stored] = []) {
        self.imagesToReturn = imagesToReturn
    }

    func upload(imageId: UUID, placeId: UUID, full: Data, thumbnail: Data) async throws {
        if shouldThrowOnUpload { throw MockSyncError.intentional }
        uploaded.append(Stored(id: imageId, placeId: placeId, thumbnail: thumbnail, full: full, createdAt: Date()))
    }

    func delete(imageId: UUID, placeId: UUID) async throws {
        if shouldThrowOnDelete { throw MockSyncError.intentional }
        deleted.append((imageId, placeId))
    }

    func downloadThumbnail(imageId: UUID, placeId: UUID) async throws -> Data? {
        imagesToReturn.first { $0.id == imageId }?.thumbnail
    }

    func downloadFull(imageId: UUID, placeId: UUID) async throws -> Data? {
        imagesToReturn.first { $0.id == imageId }?.full
    }

    func fetch(createdAfter date: Date) async throws -> [RemoteImageRef] {
        imagesToReturn
            .filter { $0.createdAt > date }
            .map { RemoteImageRef(id: $0.id, placeId: $0.placeId, createdAt: $0.createdAt) }
    }
}
