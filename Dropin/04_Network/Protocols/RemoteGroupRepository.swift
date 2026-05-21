//
//  RemoteGroupRepository.swift
//  Dropin

import Foundation

protocol RemoteGroupRepository: Sendable {
    func upsert(_ group: GroupEntity) async throws
    func fetch(updatedAfter date: Date) async throws -> [GroupEntity]
}
