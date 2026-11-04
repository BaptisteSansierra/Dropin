//
//  StubRemoteImageRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

//  No-op services used by MockContainer (previews + tests)
//  so the app target can be built without real Supabase credentials.
#if DEBUG

import Foundation

final class StubRemoteImageRepository: RemotePlaceImageRepository {
    func upload(imageId: UUID, placeId: UUID, full: Data, thumbnail: Data) async throws {}
    func delete(imageId: UUID, placeId: UUID) async throws {}
    func downloadThumbnail(imageId: UUID, placeId: UUID) async throws -> Data? { nil }
    func downloadFull(imageId: UUID, placeId: UUID) async throws -> Data? { nil }
    func fetch(createdAfter date: Date) async throws -> [RemotePlaceImageRef] { [] }
}

#endif
