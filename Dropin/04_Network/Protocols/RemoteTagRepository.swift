//
//  RemoteTagRepository.swift
//  Dropin

import Foundation

protocol RemoteTagRepository: Sendable {
    func upsert(_ tag: Tag) async throws
    /// `excludeDeleted`: skip soft-deleted rows. Only safe on a first-ever pull
    func fetch(updatedAfter date: Date, excludeDeleted: Bool) async throws -> [Tag]
}
