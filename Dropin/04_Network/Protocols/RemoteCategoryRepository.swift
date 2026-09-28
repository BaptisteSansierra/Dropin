//
//  RemoteCategoryRepository.swift
//  Dropin

import Foundation

protocol RemoteCategoryRepository: Sendable {
    func upsert(_ category: Category) async throws
    func fetch(updatedAfter date: Date) async throws -> [Category]
}
