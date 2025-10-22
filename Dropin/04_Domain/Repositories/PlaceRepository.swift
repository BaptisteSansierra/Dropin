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
    func getAll() async throws -> [PlaceEntity]
}
