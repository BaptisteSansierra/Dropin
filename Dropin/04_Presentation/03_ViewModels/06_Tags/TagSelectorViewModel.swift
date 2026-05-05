//
//  TagSelectorViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 6/10/25.
//

import SwiftUI

@MainActor
@Observable class TagSelectorViewModel {
    
    var placeTags = [TagUI]()
    var remainingTags = [TagUI]()
    var tags = [TagUI]()
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchTags: FetchTags
    @ObservationIgnored private var createTags: CreateTag

    init(_ appContainer: AppContainer,
         fetchTags: FetchTags,
         createTags: CreateTag) {
        self.appContainer = appContainer
        self.fetchTags = fetchTags
        self.createTags = createTags
    }
    
    func updateData(_ place: PlaceUI) {
        placeTags = place.tags
        remainingTags = tags.filter { tag in !place.tags.contains(where: { $0.id == tag.id }) }
        placeTags.sort(by: { $0.name < $1.name && $0.createdAt < $1.createdAt })
        remainingTags.sort(by: { $0.name < $1.name && $0.createdAt < $1.createdAt })
    }
    
    // MARK: Uses cases
    func createTag(name: String, color: String) async throws -> TagUI {
        let domainTag = TagEntity(name: name, color: color)
        try await createTags(domainTag)
        let tagUI = TagMapper.toUI(domainTag)
        tags.append(tagUI)
        tags = tags.defaultSorted()
        return tagUI
    }

    func loadTags() async throws {
        let domainTags = try await fetchTags()
        tags = domainTags.map { TagMapper.toUI($0) }
    }
}

