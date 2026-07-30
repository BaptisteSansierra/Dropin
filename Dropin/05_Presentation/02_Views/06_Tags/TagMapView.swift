//
//  TagMapView.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/6/26.
//

import SwiftUI

struct TagMapView: View {
    
    @State private var viewModel: TagMapViewModel

    init(viewModel: TagMapViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        viewModel.createGenericMapView()
            .ignoresSafeArea()
    }
}

#if DEBUG

struct MockTagMapView: View {
    var mock: MockContainer
    @State private var tag: TagUI

    var body: some View {
        mock.appContainer.createTagMapView(tagId: tag.id)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.tag = mock.getTagUI(1)
    }
}

#Preview {
    NavigationStack {
        MockTagMapView()
    }
    .environment(AppSettings())
}

#endif
