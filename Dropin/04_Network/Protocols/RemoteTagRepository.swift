//
//  RemoteTagRepository.swift
//  Dropin

import Foundation

protocol RemoteTagRepository: Sendable {
    func upsert(_ tag: Tag) async throws
    func fetch(updatedAfter date: Date) async throws -> [Tag]
}
