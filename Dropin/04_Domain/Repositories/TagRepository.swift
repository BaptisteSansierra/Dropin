//
//  TagRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
protocol TagRepository {
    func create(_ tag: TagEntity) async throws -> TagEntity
    func delete(_ tag: TagEntity) async throws
    func getAll() async throws -> [TagEntity]
}
