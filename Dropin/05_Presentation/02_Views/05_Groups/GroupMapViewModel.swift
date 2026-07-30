//
//  GroupMapViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/6/26.
//

import SwiftUI

@MainActor
@Observable class GroupMapViewModel {
    
    var groupId: UUID

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchGroupPlaces: FetchGroupPlaces
    
    init(_ appContainer: AppContainer,
         groupId: UUID,
         fetchGroupPlaces: FetchGroupPlaces) {
        self.appContainer = appContainer
        self.groupId = groupId
        self.fetchGroupPlaces = fetchGroupPlaces
    }
    
    // MARK: UI Child
    func createGenericMapView() -> GenericMapView {
        let vm = GenericMapViewModel(appContainer) {
            try await self.fetchGroupPlaces(self.groupId)
        }
        return GenericMapView(viewModel: vm)
    }

//    func createPlaceSheetView(place: Binding<PlaceUI>, detent: Binding<PresentationDetent>) -> PlaceSheetView {
//        return appContainer.createPlaceSheetView(place: place, detent: detent)
//    }
}
