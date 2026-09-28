//
//  PlaceRepository.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation

@MainActor
protocol PlaceRepository: Sendable {
    func exists(_ place: Place) async throws -> Bool
    func create(_ place: Place) async throws
    //func delete(_ place: Place) async throws
    func update(_ place: Place) async throws
    func fetch(_ id: UUID) async throws -> Place
    func fetch(categoryId: UUID) async throws -> [Place]
    func fetch(tagId: UUID) async throws -> [Place]
    func fetch() async throws -> [Place]
    func fetch(_ filter: PlaceFilter?) async throws -> [Place]
    func upsert(_ place: Place, shouldSave: Bool) async throws
    func clearTable() async throws
}
