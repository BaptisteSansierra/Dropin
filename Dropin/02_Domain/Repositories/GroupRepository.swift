//
//  GroupRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
protocol GroupRepository {
    func exists(_ group: GroupEntity) async throws -> Bool
    func create(_ group: GroupEntity) async throws
    func delete(_ group: GroupEntity) async throws
    func update(_ group: GroupEntity) async throws
    func fetch() async throws -> [GroupEntity]
    func fetchWithPlaceCount() async throws -> [(GroupEntity, Int)]
    func fetch(_ id: UUID) async throws -> GroupEntity
    func upsert(_ group: GroupEntity) async throws
}
