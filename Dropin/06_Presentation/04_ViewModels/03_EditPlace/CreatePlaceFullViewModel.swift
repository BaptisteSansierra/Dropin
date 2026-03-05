//
//  CreatePlaceFullViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI
import CoreLocation

@MainActor
@Observable class CreatePlaceFullViewModel {
    
    var showingMarkerList = false
    var showingTagsSelector = false
    var showingGroupSelector = false
    var selectedGroup: SDGroup?
    var missingName = false

    // MARK: un-tracked properties
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let coordinator: MainCoordinator
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
    func popToRoot() {
        coordinator.popToRoot()
    }

    // MARK: UI Childs
    func createTagSelectorView(place: Binding<PlaceUI>) -> TagSelectorView {
        return appContainer.createTagSelectorView(place: place)
    }
    
    func createGroupSelectorView(place: Binding<PlaceUI>) -> GroupSelectorView {
        return appContainer.createGroupSelectorView(place: place)
    }

    // MARK: Use cases
    func save(place: PlaceUI) async throws {
        let placeEntity = PlaceMapper.toDomain(place)
        try await createPlace.execute(placeEntity)
    }
    
    func retrieveTags(tagIds: [UUID]) async -> [TagUI] {
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

    func retrieveGroup(groupId: UUID) async -> GroupUI? {
        do {
            let groupEntity = try await getGroup.execute(id: groupId)
            return GroupMapper.toUI(groupEntity)
        } catch {
            assertionFailure("couldn't retrieve tag with id \(groupId)")
        }
        return nil
    }
    
    // MARK: - Actions
    func fetchAddress(coords: CLLocationCoordinate2D) async throws -> String {
        return try await LocationManager.lookUpAddress(coords: coords)
    }
}
