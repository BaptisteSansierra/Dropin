//
//  UpsertTagInSpace.swift
//  Dropin
//

import Foundation

/// Used by SyncService.pull, where the incoming tag's own spaceId (from the remote DTO)
/// must be used on insert rather than SpaceContext.currentSpaceId, as the pulled entity may
/// belong to a space other than the one currently active on this device.
@MainActor
struct UpsertTagInSpace {
    private let repository: TagRepository

    init(repository: TagRepository) {
        self.repository = repository
    }

    func callAsFunction(_ tag: Tag, spaceId: UUID, shouldSave: Bool = true) async throws {
        guard !tag.name.isEmpty else {
            throw DomainError.Tag.missingName
        }
        try await repository.upsert(tag, spaceId: spaceId, shouldSave: shouldSave)
    }
}
