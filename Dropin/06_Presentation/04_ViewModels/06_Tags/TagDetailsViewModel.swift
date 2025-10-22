//
//  TagDetailsViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/10/25.
//

import SwiftUI

@MainActor
@Observable class TagDetailsViewModel {
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var updateTag: UpdateTag
    @ObservationIgnored private var deleteTag: DeleteTag

    init(_ appContainer: AppContainer,
         updateTag: UpdateTag,
         deleteTag: DeleteTag) {
        self.appContainer = appContainer
        self.updateTag = updateTag
        self.deleteTag = deleteTag
    }
    
    // MARK: UI Child
//    func createTagDetailsView(tag: Binding<TagUI>) -> TagDetailsView {
//        return appContainer.createTagDetailsView(tag: tag)
//    }

    // MARK: use cases
    func updateTag(_ tag: TagUI) async throws {
        try await updateTag.execute(TagMapper.toDomain(tag))
    }
    
    func deleteTag(_ tag: TagUI) async throws {
        try await deleteTag.execute(TagMapper.toDomain(tag))
        tag.databaseDeleted = true
    }
}
