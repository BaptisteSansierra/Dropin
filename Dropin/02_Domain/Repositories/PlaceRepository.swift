//
//  PlaceRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
protocol PlaceRepository: Sendable {
    func exists(_ place: PlaceEntity) async throws -> Bool
    func create(_ place: PlaceEntity) async throws
    func delete(_ place: PlaceEntity) async throws
    func update(_ place: PlaceEntity) async throws
    func fetch(_ id: UUID) async throws -> PlaceEntity
    func fetch(groupId: UUID) async throws -> [PlaceEntity]
    func fetch(tagId: UUID) async throws -> [PlaceEntity]
    func fetch() async throws -> [PlaceEntity]
    func fetch(_ filter: PlaceFilter?) async throws -> [PlaceEntity]
    func upsert(_ place: PlaceEntity) async throws
}
