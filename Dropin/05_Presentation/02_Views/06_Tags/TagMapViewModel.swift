//
//  GroupMapViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/6/26.
//

import SwiftUI

@MainActor
@Observable class TagMapViewModel {
    
    var tagId: UUID

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchTagPlaces: FetchTagPlaces
    
    init(_ appContainer: AppContainer,
         tagId: UUID,
         fetchTagPlaces: FetchTagPlaces) {
        self.appContainer = appContainer
        self.tagId = tagId
        self.fetchTagPlaces = fetchTagPlaces
    }
    
    // MARK: UI Child
    func createGenericMapView() -> GenericMapView {
        let vm = GenericMapViewModel(appContainer) {
            try await self.fetchTagPlaces(self.tagId)
        }
        return GenericMapView(viewModel: vm)
    }

    func createPlaceSheetView(place: Binding<PlaceUI>, detent: Binding<PresentationDetent>) -> PlaceSheetView {
        return appContainer.createPlaceSheetView(place: place, detent: detent)
    }
}
