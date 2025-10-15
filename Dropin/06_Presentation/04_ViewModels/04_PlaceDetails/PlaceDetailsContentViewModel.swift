//
//  PlaceDetailsContentViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/10/25.
//

import SwiftUI

@MainActor
@Observable class PlaceDetailsContentViewModel {
    
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
    
    // MARK: UI Childs
    func createTagSelectorViewModel(place: Binding<PlaceUI>) -> TagSelectorView {
        return appContainer.createTagSelectorView(place: place)
    }
    
    func createGroupSelectorViewModel(place: Binding<PlaceUI>) -> GroupSelectorView {
        return appContainer.createGroupSelectorView(place: place)
    }
}
