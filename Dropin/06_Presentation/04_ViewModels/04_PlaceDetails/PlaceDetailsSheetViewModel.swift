//
//  PlaceDetailsSheetViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/25.
//

#if false

import SwiftUI

@MainActor
@Observable class PlaceDetailsSheetViewModel {

    private var coordinator: MainCoordinator

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var updatePlace: UpdatePlace
    @ObservationIgnored private var deletePlace: DeletePlace
    @ObservationIgnored private var getTags: GetTags
    @ObservationIgnored private var createTags: CreateTag
    @ObservationIgnored private var getGroups: GetGroups
    @ObservationIgnored private var createGroup: CreateGroup
    
    init(_ appContainer: AppContainer,
         coordinator: MainCoordinator,
         updatePlace: UpdatePlace,
         deletePlace: DeletePlace,
         getTags: GetTags,
         createTags: CreateTag,
         getGroups: GetGroups,
         createGroup: CreateGroup) {
        self.appContainer = appContainer
        self.coordinator = coordinator
        self.updatePlace = updatePlace
        self.deletePlace = deletePlace
        self.getTags = getTags
        self.createTags = createTags
        self.getGroups = getGroups
        self.createGroup = createGroup
    }
    
    // MARK: Navigation
    func pushPlaceDetailsView(placeId: String) {
        coordinator.pushPlaceDetailsView(placeId: placeId)
    }

    // MARK: Child UI
    func createPlaceDetailsContentView(place: Binding<PlaceUI>, editMode: Binding<PlaceEditMode>) -> PlaceDetailsContentView {
        return appContainer.createPlaceDetailsContentView(place: place, editMode: editMode)
    }
}

#endif

