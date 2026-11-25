//
//  SpaceRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/10/26.
//

import Foundation

@MainActor
protocol SpaceRepository {
    func exists(_ space: Space) async throws -> Bool
    func create(_ space: Space) async throws
    func update(_ space: Space) async throws
    func fetch() async throws -> [Space]
    func fetch(_ id: UUID) async throws -> Space
    func upsert(_ space: Space, shouldSave: Bool) async throws
    func clearTable() async throws
}
