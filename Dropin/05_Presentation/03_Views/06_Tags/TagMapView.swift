//
//  TagMapView.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/6/26.
//

import SwiftUI

struct TagMapView: View {
    
    @State private var viewModel: TagMapViewModel
    @State private var mapReloadGen: Int = 0
    @Environment(RootView.ActionBus.self) private var actionBus

    init(viewModel: TagMapViewModel) {
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

struct MockTagMapView: View {
    var mock: MockContainer
    @State private var tag: TagUIModel

    var body: some View {
        mock.appContainer.createTagMapView(tagId: tag.id, places: tag.places)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.tag = mock.getTagUIModel(1)
    }
}

#Preview {
    NavigationStack {
        MockTagMapView()
    }
    .environment(AppSettings())
}

#endif
