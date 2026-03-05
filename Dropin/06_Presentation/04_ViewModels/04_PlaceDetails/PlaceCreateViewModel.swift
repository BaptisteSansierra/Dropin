//
//  PlaceCreateViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/3/26.
//

import SwiftUI
import ContactFieldKit
import CoreLocation

@MainActor
@Observable class PlaceCreateViewModel {
    
    @ObservationIgnored private var coordinator: MainCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let createPlace: CreatePlace
    @ObservationIgnored private let getTag: GetTag
    @ObservationIgnored private let getGroup: GetGroup

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         createPlace: CreatePlace,
         getTag: GetTag,
         getGroup: GetGroup) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.createPlace = createPlace
        self.getTag = getTag
        self.getGroup = getGroup
    }
    
    // MARK: Navigation
    func popView() {
        coordinator.pop()
    }
    
    // MARK: UI Childs
    func body(place: Binding<PlaceUI>, showMissingName: Binding<Bool>) -> some View {
        return appContainer.createPlaceEditContentView(place: place,
                                                       mode: .creation,
                                                       showMissingName: showMissingName)
    }

    // MARK: Use cases
    func save(place: PlaceUI) async throws {
        let placeEntity = PlaceMapper.toDomain(place)
        try await createPlace.execute(placeEntity)
    }
    
    func retrieveTags(tagIds: [String]) async -> [TagUI] {
        var tags = [TagUI]()
        for tagId in tagIds {
            do {
                let tagEntity = try await getTag.execute(id: tagId)
                tags.append(TagMapper.toUI(tagEntity))
            } catch {
                assertionFailure("couldn't retrieve tag with id \(tagId)")
            }
        }
        return tags
    }

    func retrieveGroup(groupId: String) async -> GroupUI? {
        do {
            let groupEntity = try await getGroup.execute(id: groupId)
            return GroupMapper.toUI(groupEntity)
        } catch {
            assertionFailure("couldn't retrieve tag with id \(groupId)")
        }
        return nil
    }
    
    // MARK: - callbacks and co

}
