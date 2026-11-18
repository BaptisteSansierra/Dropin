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

    @ObservationIgnored private var coordinator: any NavigationCoordinator
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private let updatePlace: UpdatePlace
    @ObservationIgnored private let addPlaceImage: AddPlaceImage
    @ObservationIgnored private let removePlaceImage: RemovePlaceImage

    init(_ appContainer: AppContainer,
         coordinator: any NavigationCoordinator,
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
    func body(place: PlaceUIModel,
              showMissingName: Binding<Bool>,
              onDelete: @escaping () -> Void) -> some View {
        return appContainer.createPlaceEditContentView(place: place,
                                                       mode: .edit,
                                                       showMissingName: showMissingName,
                                                       onDelete: onDelete)
    }

    // MARK: Use cases
    func deletePlace(_ place: PlaceUIModel, deletedAt: Date) async throws {
        place.deletedAt = deletedAt
        try await updatePlace(PlaceMapper.toDomain(place))
    }
    
    func updatePlace(_ place: PlaceUIModel,
                     addImages: [PlaceImageUIModel],
                     deleteImageIds: [UUID],
                     completion: () -> Void) async throws {
        place.name = place.name.trimmedName
        for img in addImages {
            guard let uiImage = img.fullImage else { continue }
            _ = try await addPlaceImage(placeId: place.id, image: uiImage)
        }
        for id in deleteImageIds {
            try await removePlaceImage(id: id)
        }
        try await updatePlace(PlaceMapper.toDomain(place))
        completion()
    }

    // MARK: - callbacks and co
}
