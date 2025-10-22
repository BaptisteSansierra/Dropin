//
//  TagRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
protocol TagRepository {
    func exists(_ tag: TagEntity) async throws -> Bool
    func create(_ tag: TagEntity) async throws
    func delete(_ tag: TagEntity) async throws
    func update(_ tag: TagEntity) async throws
    func getAll() async throws -> [TagEntity]
}
