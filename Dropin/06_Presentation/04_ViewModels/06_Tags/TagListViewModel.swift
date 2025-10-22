//
//  TagListViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/10/25.
//

import SwiftUI

@MainActor
@Observable class TagListViewModel {
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var getTags: GetTags
    @ObservationIgnored private var deleteTag: DeleteTag

    init(_ appContainer: AppContainer,
         getTags: GetTags,
         deleteTag: DeleteTag) {
        self.appContainer = appContainer
        self.getTags = getTags
        self.deleteTag = deleteTag
    }
    
    // MARK: UI Child
    func createTagDetailsView(tag: Binding<TagUI>) -> TagDetailsView {
        return appContainer.createTagDetailsView(tag: tag)
    }

    // MARK: use cases
    func loadTags() async throws -> [TagUI] {
        let domainItems = try await getTags.execute()
        let items = domainItems.map { TagMapper.toUI($0) }
        return items
    }
    
    func deleteTag(_ tag: TagUI) async throws {
        try await deleteTag.execute(TagMapper.toDomain(tag))
        tag.databaseDeleted = true
    }
}
