//
//  CategoryRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
protocol CategoryRepository {
    func exists(_ category: Category) async throws -> Bool
    func create(_ category: Category) async throws
    //func delete(_ category: Category) async throws
    func update(_ category: Category) async throws
    func fetch() async throws -> [Category]
    func fetchWithPlaceCount() async throws -> [(Category, Int)]
    func fetch(_ id: UUID) async throws -> Category
    func upsert(_ category: Category, shouldSave: Bool) async throws
    func clearTable() async throws
}
