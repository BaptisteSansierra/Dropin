//
//  ImageRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import Foundation

@MainActor
protocol ImageRepository: Sendable {
    func add(placeId: UUID, thumbnail: Data, full: Data) async throws -> UUID
    func remove(id: UUID) async throws
    func fetchThumbnails(placeId: UUID) async throws -> [(id: UUID, thumbnail: Data)]
    func fetchFull(id: UUID) async throws -> Data
}
