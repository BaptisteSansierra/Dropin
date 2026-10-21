//
//  RemoteSpaceRepository.swift
//  Dropin

import Foundation

protocol RemoteSpaceRepository: Sendable {
    func upsert(_ space: Space) async throws
    /// `excludeDeleted`: skip soft-deleted rows. Only safe on a first-ever pull
    func fetch(updatedAfter date: Date, excludeDeleted: Bool) async throws -> [Space]
}
