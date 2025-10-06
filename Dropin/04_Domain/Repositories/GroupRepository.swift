//
//  GroupRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
protocol GroupRepository {
    func create(_ group: GroupEntity) async throws -> GroupEntity
    func delete(_ group: GroupEntity) async throws
    func getAll() async throws -> [GroupEntity]
}
