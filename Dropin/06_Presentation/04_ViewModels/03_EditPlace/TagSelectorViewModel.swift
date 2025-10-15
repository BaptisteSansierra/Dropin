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
    @ObservationIgnored private var getTags: GetTags
    @ObservationIgnored private var createTags: CreateTag

    init(_ appContainer: AppContainer,
         getTags: GetTags,
         createTags: CreateTag) {
        self.appContainer = appContainer
        self.getTags = getTags
        self.createTags = createTags
    }
    
    func updateData(_ place: PlaceUI) {
        placeTags = place.tags
        remainingTags = tags.filter { tag in !place.tags.contains(where: { $0.id == tag.id }) }
        placeTags.sort(by: { $0.name < $1.name && $0.creationDate < $1.creationDate })
        remainingTags.sort(by: { $0.name < $1.name && $0.creationDate < $1.creationDate })
    }
    
    func printContent() {
        print("\n----------CONTENT: ----------")
        print(Unmanaged.passUnretained(self).toOpaque())
        print("FULL TAGS : \(tags.map { $0.name })")
        print("PLAC TAGS : \(placeTags.map { $0.name })")
        print("REMA TAGS : \(remainingTags.map { $0.name })")
    }

    // MARK: Uses cases
    func createTag(name: String, color: String) async throws -> TagUI {
        let domainTag = TagEntity(name: name, color: color)
        try await createTags.execute(domainTag)
        let tagUI = TagMapper.toUI(domainTag)
        tags.append(tagUI)
        return tagUI
    }

    func loadTags() async throws {
        let domainTags = try await getTags.execute()
        tags = domainTags.map { TagMapper.toUI($0) }
    }
}

