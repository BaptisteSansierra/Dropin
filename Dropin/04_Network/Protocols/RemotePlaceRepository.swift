//
//  RemotePlaceRepository.swift
//  Dropin

import Foundation

protocol RemotePlaceRepository: Sendable {
    func upsert(_ place: Place) async throws
    /// `excludeDeleted`: skip soft-deleted rows. Only safe on a first-ever pull
    func fetch(updatedAfter date: Date, excludeDeleted: Bool) async throws -> [Place]
}
