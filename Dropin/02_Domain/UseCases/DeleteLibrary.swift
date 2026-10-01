//
//  DeleteLibrary.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import Foundation

@MainActor
struct DeleteLibrary {
    private let generalRepository: GeneralRepository
    private let placeRepository: PlaceRepository
    private let groupRepository: CategoryRepository
    private let tagRepository: TagRepository

    init(generalRepository: GeneralRepository,
         placeRepository: PlaceRepository,
         groupRepository: CategoryRepository,
         tagRepository: TagRepository) {
        self.generalRepository = generalRepository
        self.placeRepository = placeRepository
        self.groupRepository = groupRepository
        self.tagRepository = tagRepository
    }

    func callAsFunction() async throws {
        let deleteAt = Date.now
        let upsertPlace = UpsertPlace(repository: placeRepository)
        let upsertCategory = UpsertCategory(repository: groupRepository)
        let upsertTag = UpsertTag(repository: tagRepository)
        let saveContext = SaveContext(repository: generalRepository)

        // Soft delete everything
        do {
            for tag in try await tagRepository.fetch() {
                try await upsertTag(tag.deleted(deletedAt: deleteAt), shouldSave: false)
            }
            for category in try await groupRepository.fetch() {
                try await upsertCategory(category.deleted(deletedAt: deleteAt), shouldSave: false)
            }
            for place in try await placeRepository.fetch() {
                try await upsertPlace(place.deleted(deletedAt: deleteAt), shouldSave: false)
            }
        } catch {
            // In case anything fails, restore it all instead of getting half the job done and not commited to disk
            let rollbackContext = RollbackContext(repository: generalRepository)
            await rollbackContext()
            throw error
        }
        try await saveContext()
    }
}
