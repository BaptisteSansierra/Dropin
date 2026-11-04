//
//  UpsertCategoryInSpace.swift
//  Dropin
//

import Foundation

/// Used by SyncService.pull, where the incoming category's own spaceId (from the remote DTO)
/// must be used on insert rather than SpaceContext.currentSpaceId, as the pulled entity may
/// belong to a space other than the one currently active on this device.
@MainActor
struct UpsertCategoryInSpace {
    private let repository: CategoryRepository

    init(repository: CategoryRepository) {
        self.repository = repository
    }

    func callAsFunction(_ category: Category, spaceId: UUID, shouldSave: Bool = true) async throws {
        guard !category.name.isEmpty else {
            throw DomainError.Category.missingName
        }
        try await repository.upsert(category, spaceId: spaceId, shouldSave: shouldSave)
    }
}
