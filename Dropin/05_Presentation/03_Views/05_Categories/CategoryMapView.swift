//
//  CategoryMapView.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/6/26.
//

import SwiftUI

struct CategoryMapView: View {
    
    @State private var viewModel: CategoryMapViewModel
    @State private var mapReloadGen: Int = 0
    @Environment(RootView.ActionBus.self) private var actionBus

    init(viewModel: CategoryMapViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        viewModel.createGenericMapView(mapReloadGen: $mapReloadGen)
            .ignoresSafeArea()
            .onReceive(actionBus.actionPublisher) { handleAction($0) }
    }
    
    private func handleAction(_ action: RootView.ActionBus.Action) {
        switch action {
            case .reloadMainPlaces:
                mapReloadGen += 1
            default: ()
        }
    }
}


#if DEBUG

struct MockCategoryMapView: View {
    var mock: MockContainer
    @State private var category: CategoryUIModel

    var body: some View {
        mock.appContainer.createCategoryMapView(categoryId: category.id, places: category.places)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.category = mock.getCategoryUIModel()
    }
}

#Preview {
    NavigationStack {
        MockCategoryMapView()
    }
    .environment(AppSettings())
}

#endif
