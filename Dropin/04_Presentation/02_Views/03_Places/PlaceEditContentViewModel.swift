//
//  PlaceEditContentViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/2/26.
//

import SwiftUI
import UIKit
import ContactFieldKit
import CoreLocation

@MainActor
@Observable class PlaceEditContentViewModel {

    enum Mode {
        case edit
        case creation
    }

    @ObservationIgnored var mode: Mode

    @ObservationIgnored private var coordinator: MainCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let updatePlace: UpdatePlace
    @ObservationIgnored private let deletePlace: DeletePlace
    @ObservationIgnored private let getPlaceThumbnails: GetPlaceThumbnails
    @ObservationIgnored private let getPlaceImage: GetPlaceImage

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         updatePlace: UpdatePlace,
         deletePlace: DeletePlace,
         getPlaceThumbnails: GetPlaceThumbnails,
         getPlaceImage: GetPlaceImage,
         mode: Mode) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.updatePlace = updatePlace
        self.deletePlace = deletePlace
        self.getPlaceThumbnails = getPlaceThumbnails
        self.getPlaceImage = getPlaceImage
        self.mode = mode
    }

    // MARK: Navigation
    func popView() {
        coordinator.pop()
    }

    func pushLookupPlacesView(placeId: UUID) {
        coordinator.pushLookupPlacesEditView(placeId: placeId)
    }

    // MARK: UI Childs
    func createTagSelectorView(place: Binding<PlaceUI>) -> TagSelectorView {
        return appContainer.createTagSelectorView(place: place)
    }

    func createGroupSelectorView(place: Binding<PlaceUI>) -> GroupSelectorView {
        return appContainer.createGroupSelectorView(place: place)
    }

    // MARK: Use cases
    func updatePlace(_ place: PlaceUI) async throws {
        let placeEntity = PlaceMapper.toDomain(place)
        try await updatePlace(placeEntity)
    }

    func deletePlace(_ place: PlaceUI) async throws {
        try await deletePlace(PlaceMapper.toDomain(place))
        if place.deletedAt == nil {
            assertionFailure("Model should have been marked deleted already for SwiftUI safety")
            place.deletedAt = Date()
        }
    }

    func loadThumbnails(for place: PlaceUI) {
        Task {
            do {
                let fetched = try await getPlaceThumbnails(placeId: place.id)
                for idx in place.images.indices {
                    guard let dbId = place.images[idx].dbId,
                          let match = fetched.first(where: { $0.id == dbId }) else { continue }
                    place.images[idx].thumbnail = match.thumbnail
                }
            } catch {
                Log.error("Failed to load thumbnails for place \(place.id): \(error)")
            }
        }
    }

    func addImage(to place: PlaceUI, image: UIImage) {
        Task {
            let size = DropinApp.storage.thumbnailSize
            let thumbImage = await image.byPreparingThumbnail(ofSize: CGSize(width: size, height: size)) ?? image
            guard let thumbnailData = thumbImage.jpegData(compressionQuality: 0.8) else { return }
            place.images.append(PlaceImageUI(thumbnail: thumbnailData, fullImage: image))
        }
    }

    func removeImage(withId id: UUID, from place: PlaceUI) {
        place.images.removeAll { $0.id == id }
    }

    func getFullImage(dbId: UUID) async -> Data? {
        do {
            return try await getPlaceImage(id: dbId)
        } catch {
            Log.error("Failed to load full image \(dbId): \(error)")
            return nil
        }
    }
}
