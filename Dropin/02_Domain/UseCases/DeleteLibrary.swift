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
    private let spaceRepository: SpaceRepository
    private let placeRepository: PlaceRepository
    private let categoryRepository: CategoryRepository
    private let tagRepository: TagRepository

    init(generalRepository: GeneralRepository,
         spaceRepository: SpaceRepository,
         placeRepository: PlaceRepository,
         categoryRepository: CategoryRepository,
         tagRepository: TagRepository) {
        self.generalRepository = generalRepository
        self.spaceRepository = spaceRepository
        self.placeRepository = placeRepository
        self.categoryRepository = categoryRepository
        self.tagRepository = tagRepository
    }

    func callAsFunction() async throws {
        let deleteAt = Date.now
        let upsertSpace = UpsertSpace(repository: spaceRepository)
        let upsertPlace = UpsertPlace(repository: placeRepository)
        let upsertCategory = UpsertCategory(repository: categoryRepository)
        let upsertTag = UpsertTag(repository: tagRepository)
        let saveContext = SaveContext(repository: generalRepository)

        // Soft delete everything in current space
        do {
            for tag in try await tagRepository.fetch() {
                try await upsertTag(tag.deleted(deletedAt: deleteAt), shouldSave: false)
            }
            for category in try await categoryRepository.fetch() {
                try await upsertCategory(category.deleted(deletedAt: deleteAt), shouldSave: false)
            }
            for place in try await placeRepository.fetch() {
                try await upsertPlace(place.deleted(deletedAt: deleteAt), shouldSave: false)
            }
            for space in try await spaceRepository.fetch() {
                try await upsertSpace(space.deleted(deletedAt: deleteAt), shouldSave: false)
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
