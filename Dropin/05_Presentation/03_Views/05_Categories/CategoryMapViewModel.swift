//
//  CategoryMapViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/6/26.
//

import SwiftUI

@MainActor
@Observable class CategoryMapViewModel {
    
    var categoryId: UUID

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchCategoryPlaces: FetchCategoryPlaces
    
    init(_ appContainer: AppContainer,
         categoryId: UUID,
         fetchCategoryPlaces: FetchCategoryPlaces) {
        self.appContainer = appContainer
        self.categoryId = categoryId
        self.fetchCategoryPlaces = fetchCategoryPlaces
    }
    
    // MARK: UI Child
    func createGenericMapView() -> GenericMapView {
        let vm = GenericMapViewModel(appContainer) {
            try await self.fetchCategoryPlaces(self.categoryId)
                .filter({ $0.isActive })
        }
        return GenericMapView(viewModel: vm)
    }

//    func createPlaceSheetView(place: Binding<PlaceUIModel>, detent: Binding<PresentationDetent>) -> PlaceSheetView {
//        return appContainer.createPlaceSheetView(place: place, detent: detent)
//    }
}
