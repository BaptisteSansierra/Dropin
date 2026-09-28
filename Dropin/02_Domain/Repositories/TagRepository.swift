//
//  TagRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
protocol TagRepository {
    func exists(_ tag: Tag) async throws -> Bool
    func create(_ tag: Tag) async throws
    //func delete(_ tag: Tag) async throws
    func update(_ tag: Tag) async throws
    func fetch() async throws -> [Tag]
    func fetchWithPlaceCount() async throws -> [(Tag, Int)]
    func fetch(_ id: UUID) async throws -> Tag
    func upsert(_ tag: Tag, shouldSave: Bool) async throws
    func clearTable() async throws
}
