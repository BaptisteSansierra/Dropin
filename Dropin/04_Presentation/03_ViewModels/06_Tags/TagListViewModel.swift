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

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchTagsWithCount: FetchTagsWithCount
    @ObservationIgnored private var deleteTag: DeleteTag

    init(_ appContainer: AppContainer,
         coordinator: TagCoordinator,
         fetchTagsWithCount: FetchTagsWithCount,
         deleteTag: DeleteTag) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.fetchTagsWithCount = fetchTagsWithCount
        self.deleteTag = deleteTag
    }
    
    // MARK: UI Child
    func createTagDetailsView(tag: Binding<TagUI>) -> TagDetailsView {
        return appContainer.createTagDetailsView(tag: tag)
    }

    // MARK: Navigation
    func pushTagDetailsView(tagId: UUID) {
        coordinator.pushTagDetailsView(tagId: tagId)
    }

    // MARK: use cases
    func loadTags() async throws -> [TagUI] {
        let result = try await fetchTagsWithCount.execute()
        let items = result.map { TagMapper.toUI($0, placeCount: $1) }
        return items
    }
    
    func deleteTag(_ tag: TagUI) async throws {
        try await deleteTag.execute(TagMapper.toDomain(tag))
        if tag.deletedAt == nil {
            assertionFailure("Model should have been marked deleted already for SwiftUI safety")
            tag.deletedAt = Date()
        }
    }
}
