//
//  PlaceDetailsViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/25.
//

import SwiftUI

@MainActor
@Observable class PlaceDetailsViewModel {
    
    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var updatePlace: UpdatePlace
    @ObservationIgnored private var deletePlace: DeletePlace
    @ObservationIgnored private var getTags: GetTags
    @ObservationIgnored private var createTags: CreateTag
    @ObservationIgnored private var getGroups: GetGroups
    @ObservationIgnored private var createGroup: CreateGroup
    
    init(_ appContainer: AppContainer,
         updatePlace: UpdatePlace,
         deletePlace: DeletePlace,
         getTags: GetTags,
         createTags: CreateTag,
         getGroups: GetGroups,
         createGroup: CreateGroup) {
        self.appContainer = appContainer
        self.updatePlace = updatePlace
        self.deletePlace = deletePlace
        self.getTags = getTags
        self.createTags = createTags
        self.getGroups = getGroups
        self.createGroup = createGroup
    }
    
    // MARK: Child UI
    func createPlaceDetailsContentView(place: Binding<PlaceUI>, editMode: Binding<PlaceEditMode>) -> PlaceDetailsContentView {
        return appContainer.createPlaceDetailsContentView(place: place, editMode: editMode)
    }
    
    // MARK: Use cases
    func deletePlace(_ place: PlaceUI) async throws {
        try await deletePlace.execute(PlaceMapper.toDomain(place))
        place.databaseDeleted = true
    }
    
    func updatePlace(_ place: PlaceUI) async throws {
        try await updatePlace.execute(PlaceMapper.toDomain(place))
    }
}
