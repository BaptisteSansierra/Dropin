//
//  RemoteCategoryRepository.swift
//  Dropin

import Foundation

protocol RemoteCategoryRepository: Sendable {
    func upsert(_ category: Category) async throws
    /// `excludeDeleted`: skip soft-deleted rows. Only safe on a first-ever pull
    func fetch(updatedAfter date: Date, excludeDeleted: Bool) async throws -> [Category]
}
