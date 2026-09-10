//
//  TagListViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/10/25.
//

import SwiftUI

@MainActor
@Observable class TagListViewModel {
    
    var coordinator: TagCoordinator
    var syncStatus: SyncStatus
    var tags: [TagUI] = []
    var showingRemoveAlert: Bool = false
    var tagToRemove: TagUI? = nil

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchTagsWithCount: FetchTagsWithCount
    @ObservationIgnored private var updateTag: UpdateTag

    init(_ appContainer: AppContainer,
         coordinator: TagCoordinator,
         fetchTagsWithCount: FetchTagsWithCount,
         updateTag: UpdateTag,
         syncStatus: SyncStatus) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.fetchTagsWithCount = fetchTagsWithCount
        self.updateTag = updateTag
        self.syncStatus = syncStatus
    }
    
    // MARK: Actions
    func softDeleteTag(_ index: Int) async throws {
        // Soft delete tag
        tags[index].deletedAt = Date()
        try await updateTag(tags[index])
        tagToRemove = nil
    }
    
    // MARK: UI Child
    func createTagDetailsView(tag: TagUI) -> TagDetailsView {
        return appContainer.createTagDetailsView(tag: tag)
    }

    func createTagMapView(tagId: UUID) -> TagMapView {
        return appContainer.createTagMapView(tagId: tagId)
    }
    
    func createPlaceEditView(place: PlaceUI) -> PlaceEditView {
        return appContainer.createPlaceEditView(place: place)
    }

    // MARK: Navigation
    func pushTagDetailsView(tagId: UUID) {
        coordinator.pushTagDetailsView(tagId: tagId)
    }

    // MARK: use cases
    func loadTags() async throws {
        let result = try await fetchTagsWithCount()
        let items = result
            .map { TagMapper.toUI($0, placeCount: $1) }
        tags = items
    }
    
    private func updateTag(_ tag: TagUI) async throws {
        try await updateTag(TagMapper.toDomain(tag))
    }
}
