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

    @ObservationIgnored private var coordinator: PlaceCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let createPlace: CreatePlace
    @ObservationIgnored private let getTag: FetchTag
    @ObservationIgnored private let getCategory: FetchCategory
    @ObservationIgnored private let createTag: CreateTag
    @ObservationIgnored private let createCategory: CreateCategory
    @ObservationIgnored private let addPlaceImage: AddPlaceImage

    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         createPlace: CreatePlace,
         getTag: FetchTag,
         getCategory: FetchCategory,
         createTag: CreateTag,
         createCategory: CreateCategory,
         addPlaceImage: AddPlaceImage) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.createPlace = createPlace
        self.getTag = getTag
        self.getCategory = getCategory
        self.createTag = createTag
        self.createCategory = createCategory
        self.addPlaceImage = addPlaceImage
    }

    // MARK: Navigation
    func popToRoot() {
        coordinator.popToRoot()
    }

    func pop() {
        coordinator.pop()
    }

    // MARK: UI Childs
    func body(place: Binding<PlaceUIModel>, showMissingName: Binding<Bool>) -> some View {
        return appContainer.createPlaceEditContentView(place: place,
                                                       mode: .creation,
                                                       showMissingName: showMissingName)
    }

    // MARK: Use cases
    func save(place: PlaceUIModel) async throws {
        let placeEntity = PlaceMapper.toDomain(place)
        try await ensureCategoryExists(placeEntity.category)
        try await ensureTagsExist(placeEntity.tags)
        try await createPlace(placeEntity)
        for img in place.images where img.dbId == nil {
            guard let uiImage = img.fullImage else { continue }
            _ = try await addPlaceImage(placeId: place.id, image: uiImage)
        }
    }

    private func ensureCategoryExists(_ category: Category?) async throws {
        guard let category else { return }
        do {
            _ = try await getCategory(id: category.id)
        } catch {
            try await createCategory(category)
        }
    }

    private func ensureTagsExist(_ tags: [Tag]) async throws {
        for tag in tags {
            do {
                _ = try await getTag(id: tag.id)
            } catch {
                try await createTag(tag)
            }
        }
    }

    func retrieveTags(tagIds: [UUID]) async -> [TagUIModel] {
        var tags = [TagUIModel]()
        for tagId in tagIds {
            do {
                let tagEntity = try await getTag(id: tagId)
                tags.append(TagMapper.toUI(tagEntity))
            } catch {
                assertionFailure("couldn't retrieve tag with id \(tagId)")
            }
        }
        return tags
    }

    func retrieveCategory(categoryId: UUID) async -> CategoryUIModel? {
        do {
            let categoryEntity = try await getCategory(id: categoryId)
            return CategoryMapper.toUI(categoryEntity)
        } catch {
            assertionFailure("couldn't retrieve tag with id \(categoryId)")
        }
        return nil
    }

    // MARK: - callbacks and co

}
