//
//  PlaceEditViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/3/26.
//

import SwiftUI
import ContactFieldKit
import CoreLocation

@MainActor
@Observable class PlaceEditViewModel {

    @ObservationIgnored private var coordinator: MainCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let updatePlace: UpdatePlace
    @ObservationIgnored private let addPlaceImage: AddPlaceImage
    @ObservationIgnored private let removePlaceImage: RemovePlaceImage

    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         updatePlace: UpdatePlace,
         addPlaceImage: AddPlaceImage,
         removePlaceImage: RemovePlaceImage) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.updatePlace = updatePlace
        self.addPlaceImage = addPlaceImage
        self.removePlaceImage = removePlaceImage
    }

    // MARK: Navigation
    func pop() {
        coordinator.pop()
    }

    // MARK: UI Childs
    func body(place: Binding<PlaceUI>, showMissingName: Binding<Bool>) -> some View {
        return appContainer.createPlaceEditContentView(place: place,
                                                       mode: .edit,
                                                       showMissingName: showMissingName)
    }

    // MARK: Use cases
    func updatePlace(_ place: PlaceUI, addImages: [PlaceImageUI], deleteImageIds: [UUID]) async throws {
        for img in addImages {
            guard let uiImage = img.fullImage else { continue }
            _ = try await addPlaceImage(placeId: place.id, image: uiImage)
        }
        for id in deleteImageIds {
            try await removePlaceImage(id: id)
        }
        try await updatePlace(PlaceMapper.toDomain(place))
    }

    // MARK: - callbacks and co
}
