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
    
    var reachabilityService: any ReachabilityServiceProtocol

    // Apple POI fetched data
    var applePhoneNumber: String?
    var appleURL: URL?
    var applePOIError: ApplePOIError?
    var applePOILoading = false
    var isUnlinkConfirmationPresented = false

    @ObservationIgnored var mode: Mode
    @ObservationIgnored private var coordinator: PlaceCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let markPlacePOINotFound: MarkPlacePOINotFound
    @ObservationIgnored private let unmarkPlacePOINotFound: UnmarkPlacePOINotFound
    @ObservationIgnored private let unlinkPlacePOI: UnlinkPlacePOI
    @ObservationIgnored private let updatePlace: UpdatePlace
    @ObservationIgnored private let getPlaceThumbnails: GetPlaceThumbnails
    @ObservationIgnored private let getPlaceImage: GetPlaceImage
    @ObservationIgnored private let applePOIService: any ApplePOIServiceProtocol

    init(_ appContainer: AppContainer,
         coordinator: PlaceCoordinator,
         reachabilityService: any ReachabilityServiceProtocol,
         markPlacePOINotFound: MarkPlacePOINotFound,
         unmarkPlacePOINotFound: UnmarkPlacePOINotFound,
         unlinkPlacePOI: UnlinkPlacePOI,
         updatePlace: UpdatePlace,
         getPlaceThumbnails: GetPlaceThumbnails,
         getPlaceImage: GetPlaceImage,
         applePOIService: any ApplePOIServiceProtocol,
         mode: Mode) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.reachabilityService = reachabilityService
        self.markPlacePOINotFound = markPlacePOINotFound
        self.unmarkPlacePOINotFound = unmarkPlacePOINotFound
        self.unlinkPlacePOI = unlinkPlacePOI
        self.updatePlace = updatePlace
        self.getPlaceThumbnails = getPlaceThumbnails
        self.getPlaceImage = getPlaceImage
        self.applePOIService = applePOIService
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
    func createTagSelectorView(place: Binding<PlaceUIModel>) -> TagSelectorView {
        return appContainer.createTagSelectorView(place: place)
    }

    func createCategorySelectorView(place: Binding<PlaceUIModel>) -> CategorySelectorView {
        return appContainer.createCategorySelectorView(place: place)
    }

    // MARK: Use cases
    func updatePlace(_ place: PlaceUIModel) async throws {
        let placeEntity = PlaceMapper.toDomain(place)
        try await updatePlace(placeEntity)
    }

    func loadThumbnails(for place: PlaceUIModel) {
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

    func addImage(to place: PlaceUIModel, image: UIImage) {
        Task {
            let size = DropinApp.storage.thumbnailSize
            let thumbImage = await image.byPreparingThumbnail(ofSize: CGSize(width: size, height: size)) ?? image
            guard let thumbnailData = thumbImage.jpegData(compressionQuality: 0.8) else { return }
            place.images.append(PlaceImageUIModel(thumbnail: thumbnailData, fullImage: image))
        }
    }

    func removeImage(withId id: UUID, from place: PlaceUIModel) {
        place.images.removeAll { $0.id == id }
    }

    func getFullImage(dbId: UUID, placeId: UUID) async -> Data? {
        await getPlaceImage(id: dbId, placeId: placeId).data
    }
    
    func fetchAppleDataIfNeeded(for place: PlaceUIModel) async {
        guard let appleId = place.applePlaceID else { return }
        applePOILoading = true
        applePOIError = nil
        defer {
            applePOILoading = false
        }
        do {
            let mapItem = try await applePOIService.details(for: appleId)
            applePhoneNumber = mapItem.phoneNumber
            appleURL = mapItem.url
            if let _ = place.appleNotFoundAt {
                // This place has been 'notFound' at some point, it seems Apple popped it back
                unmarkPOINotFound(place)
            }
        } catch let error as ApplePOIError {
            applePOIError = error
            if error == .notFound {
                markPOINotFound(place)
            }
        } catch {
            applePOIError = ApplePOIError.unknown(error)
        }
    }
    
    func unlinkPOI(_ place: PlaceUIModel) {
        place.applePlaceID = nil
        Task {
            try? await unlinkPlacePOI(uuid: place.id)
        }
    }
    
    private func markPOINotFound(_ place: PlaceUIModel) {
        // Store the appleNotFoundAt value without applying the possible edits on current place
        // by using the MarkPlacePOINotFound use case
        guard place.appleNotFoundAt == nil else {
            // This place was already marked previously, we want to keep the date of the first 'not found' occurence
            return
        }
        let notFoundAt = Date()
        place.appleNotFoundAt = notFoundAt
        Task {
            // Error can be ignored, no useful data to show to the user here
            try? await markPlacePOINotFound(uuid: place.id, date: notFoundAt)
        }
    }
    
    private func unmarkPOINotFound(_ place: PlaceUIModel) {
        place.appleNotFoundAt = nil
        Task {
            try? await unmarkPlacePOINotFound(uuid: place.id)
        }
    }
}
