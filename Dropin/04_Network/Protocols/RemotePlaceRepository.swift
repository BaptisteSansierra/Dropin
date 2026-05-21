//
//  RemotePlaceRepository.swift
//  Dropin

import Foundation

protocol RemotePlaceRepository: Sendable {
    func upsert(_ place: PlaceEntity) async throws
    func fetch(updatedAfter date: Date) async throws -> [PlaceEntity]
}
