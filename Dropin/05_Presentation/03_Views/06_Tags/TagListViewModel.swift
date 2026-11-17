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
    var tags: [TagUIModel] = []
    var showingRemoveAlert: Bool = false
    var tagToRemove: TagUIModel? = nil
    var presentCreateSheet: Bool = false
    var genericError: GenericError? = nil

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchTagsWithCount: FetchTagsWithCount
    @ObservationIgnored private var createTag: CreateTag
    @ObservationIgnored private var updateTag: UpdateTag

    init(_ appContainer: AppContainer,
         coordinator: TagCoordinator,
         fetchTagsWithCount: FetchTagsWithCount,
         createTag: CreateTag,
         updateTag: UpdateTag,
         syncStatus: SyncStatus) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.fetchTagsWithCount = fetchTagsWithCount
        self.createTag = createTag
        self.updateTag = updateTag
        self.syncStatus = syncStatus
    }
    
    // MARK: Actions
    func softDeleteTag(_ index: Int) async {
        // Soft delete tag
        tags[index].deletedAt = Date()
        await updateTag(tags[index])
        tagToRemove = nil
    }
    
    // MARK: UI Child
    func createTagDetailsView(tag: TagUIModel) -> TagDetailsView {
        return appContainer.createTagDetailsView(tag: tag)
    }

    func createTagMapView(tagId: UUID, places: [PlaceUIModel]) -> TagMapView {
        return appContainer.createTagMapView(tagId: tagId, places: places)
    }
    
    func createPlaceEditView(place: PlaceUIModel) -> PlaceEditView {
        return appContainer.createPlaceEditView(place: place)
    }

    // MARK: Navigation
    func pushTagDetailsView(tagId: UUID) {
        coordinator.pushTagDetailsView(tagId: tagId)
    }

    func createLookupPlacesView(place: PlaceUIModel) -> LookupPlacesView {
        return appContainer.createLookupPlacesView(editedPlace: place) { item in
            // Apply change on the existing place
            // This VM is not in charge of propagating to database (PlaceEditView is in charge)
            place.address = item.address
            place.coordinates = item.coordinates
            // And pop address lookup view
            self.coordinator.pop()
            #if DEBUG
            // Check the navigation path is correct
            guard let lastNavItem = self.coordinator.path.last else {
                assertionFailure("Empty navigation path")
                return
            }
            switch lastNavItem {
                case .tagPlaceEdit: ()
                default: assertionFailure("Unexpected navigation path, '.tagPlaceEdit' is supposed to be last")
            }
            #endif
        }
    }

    // MARK: use cases
    func loadTags() async {
        do {
            let result = try await fetchTagsWithCount()
            let items = result
                .map { TagMapper.toUI($0, placeCount: $1) }
            tags = items
        } catch is CancellationError {
        } catch {
            genericError = .fetchDatabase(error)
        }
    }
    
    func createTag(name: String, color: String) async {
        do {
            let tag = Tag(name: name, color: color)
            try await createTag(tag)
            await loadTags()
        } catch is CancellationError {
        } catch {
            genericError = .updateDatabase(error)
        }
    }

    private func updateTag(_ tag: TagUIModel) async {
        do {
            try await updateTag(TagMapper.toDomain(tag))
        } catch is CancellationError {
        } catch {
            genericError = .updateDatabase(error)
        }
    }
}
