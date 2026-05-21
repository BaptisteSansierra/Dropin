//
//  RemoteTagRepository.swift
//  Dropin

import Foundation

protocol RemoteTagRepository: Sendable {
    func upsert(_ tag: TagEntity) async throws
    func fetch(updatedAfter date: Date) async throws -> [TagEntity]
}
