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
        
        print("CREATED TAG SELECTOR @\(print(Unmanaged.passUnretained(self).toOpaque()))")
    }
    
    deinit {
        print("DELETED TAG SELECTOR")
    }
        
//    func addTag(_ tag: TagUI, place: Bindable<PlaceUI>) async throws {
//        place.tags.append(tag)
//        updateData(place)
//    }
//
//    func removeTag(_ tag: TagUI, place: Bindable<PlaceUI>) {
//        guard let index = place.tags.firstIndex(of: tag) else {
//            assertionFailure("Couldn't remove tag \(tag.name) from selection")
//            return
//        }
//        place.tags.remove(at: index)
//        try await updateData()
//    }
    
    func updateData(_ place: PlaceUI) {
        placeTags = place.tags
        remainingTags = tags.filter { tag in !place.tags.contains(where: { $0.id == tag.id }) }
        placeTags.sort(by: { $0.name < $1.name && $0.creationDate < $1.creationDate })
        remainingTags.sort(by: { $0.name < $1.name && $0.creationDate < $1.creationDate })
        
        print("\n----------UPDATEDATA: ----------")
        print(Unmanaged.passUnretained(self).toOpaque())
        print("PLACE  TAGS : \(placeTags.map { $0.name })")
        print("REMAIN TAGS : \(remainingTags.map { $0.name })")
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

//        tags = [TagEntity(name: "PIPO", color: "AABBCC"),
//                TagEntity(name: "CACO", color: "CCAA33"),
//                TagEntity(name: "BIBO", color: "22FFCC"),
//                ]
//
        let domainTags = try await getTags.execute()
        tags = domainTags.map { TagMapper.toUI($0) }
    }
}

