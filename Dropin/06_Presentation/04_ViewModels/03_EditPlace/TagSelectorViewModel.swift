//
//  TagSelectorViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 6/10/25.
//

import Foundation

@MainActor
@Observable class TagSelectorViewModel {
    
    var place: PlaceEntity
    var placeTags = [TagEntity]()
    var remainingTags = [TagEntity]()

    @ObservationIgnored private var tags = [TagEntity]()
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var getTags: GetTags
    @ObservationIgnored private var createTags: CreateTag

    init(_ appContainer: AppContainer, place: PlaceEntity, getTags: GetTags, createTags: CreateTag) {
        self.appContainer = appContainer
        self.place = place
        self.getTags = getTags
        self.createTags = createTags
    }
 
    func loadTags() async throws {
        tags = try await getTags.execute()
        guard place.tags.count > 0 else {
            placeTags = []
            remainingTags = tags
            return
        }
        // Check place tags are found in tags list, else inconsistency
        for placeTag in place.tags {
            if let tag = tags.first(where: { $0.id ==  placeTag.id}) {
                placeTags.append(tag)
            } else {
                assertionFailure("Tags inconsistency: \(placeTag.name) linked to place \(place.name) but not found in full tag list")
            }
        }
        // Get remaining tags
        remainingTags = tags.filter { tag in
            return !placeTags.contains(where: { $0.id == tag.id })
        }
        // Sorting
        sortPlaces()
    }

    func createTag(name: String, color: String) async throws {
        let tag = try await createTags.execute(name: name, color: color)
        tags.append(tag)
        placeTags.append(tag)
    }
    
    func removeTagFromPlace(_ tag: TagEntity) {
        guard let index = placeTags.firstIndex(where: { $0.id == tag.id }) else {
            assertionFailure("Couldn't remove tag \(tag.name) from selection")
            return
        }
        placeTags.remove(at: index)
        remainingTags.append(tag)
        sortPlaces()
        // Mirror modifications to place
        place.tags = placeTags
    }
    
    func addTagToPlace(_ tag: TagEntity) {
        guard let index = remainingTags.firstIndex(where: { $0.id == tag.id }) else {
            assertionFailure("Couldn't add tag \(tag.name) to place")
            return
        }
        remainingTags.remove(at: index)
        placeTags.append(tag)
        sortPlaces()
        // Mirror modifications to place
        place.tags = placeTags
    }
    
    private func sortPlaces() {
        placeTags.sort(by: { $0.name < $1.name && $0.creationDate < $1.creationDate })
        remainingTags.sort(by: { $0.name < $1.name && $0.creationDate < $1.creationDate })
    }
}
