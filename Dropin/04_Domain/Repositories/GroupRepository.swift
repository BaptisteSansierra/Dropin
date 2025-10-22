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
    func getAll() async throws -> [GroupEntity]
}
