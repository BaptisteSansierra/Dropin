//
//  MainViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import Foundation

@MainActor
@Observable class MainViewModel {
    @ObservationIgnored private var appContainer: AppContainer
    
    init(_ appContainer: AppContainer) {
        self.appContainer = appContainer
    }
    
    func createPlacesMapView() -> PlacesMapView {
        return appContainer.createPlacesMapView()
    }
    
//    func createPlacesListView() -> PlacesListView {
//        return appContainer.createPlacesListView()
//    }
}
