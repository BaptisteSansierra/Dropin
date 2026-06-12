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
    //@ObservationIgnored private let deletePlace: DeletePlace
    @ObservationIgnored private let getPlaceThumbnails: GetPlaceThumbnails
    @ObservationIgnored private let getPlaceImage: GetPlaceImage

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         updatePlace: UpdatePlace,
         //deletePlace: DeletePlace,
         getPlaceThumbnails: GetPlaceThumbnails,
         getPlaceImage: GetPlaceImage,
         mode: Mode) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.updatePlace = updatePlace
        //self.deletePlace = deletePlace
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

    
//    func deletePlace(_ place: PlaceUI) async throws {
//        try await deletePlace(PlaceMapper.toDomain(place))
//        if place.deletedAt == nil {
//            assertionFailure("Model should have been marked deleted already for SwiftUI safety")
//            place.deletedAt = Date()
//        }
//    }

    func loadThumbnails(for place: PlaceUI) {
        Task {
            do {
                let fetched = try await getPlaceThumbnails(placeId: place.id)
                for entry in fetched {
                    if let idx = place.images.firstIndex(where: { $0.dbId == entry.id }) {
                        place.images[idx].thumbnail = entry.state.data
                    }
                    if entry.state == .downloading {
                        Task { [weak self] in
                            guard let self else { return }
                            let final = await self.getPlaceThumbnails.awaitThumbnail(imageId: entry.id, placeId: place.id)
                            if let idx = place.images.firstIndex(where: { $0.dbId == entry.id }) {
                                place.images[idx].thumbnail = final.data
                            }
                        }
                    }
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

    func getFullImage(dbId: UUID, placeId: UUID) async -> Data? {
        await getPlaceImage(id: dbId, placeId: placeId).data
    }
}
