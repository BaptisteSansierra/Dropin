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
    var places: [PlaceUIModel]

    @ObservationIgnored private var appContainer: AppContainer
    
    init(_ appContainer: AppContainer,
         categoryId: UUID,
         places: [PlaceUIModel]) {
        self.appContainer = appContainer
        self.categoryId = categoryId
        self.places = places
    }
    
    // MARK: UI Child
    func createGenericMapView(mapReloadGen: Binding<Int>) -> GenericMapView {
        let vm = GenericMapViewModel(appContainer, places: places)
        return GenericMapView(viewModel: vm, mapReloadGen: mapReloadGen)
    }
}
