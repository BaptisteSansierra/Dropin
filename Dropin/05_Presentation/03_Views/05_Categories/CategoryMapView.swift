//
//  CategoryMapView.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/6/26.
//

import SwiftUI

struct CategoryMapView: View {
    
    @State private var viewModel: CategoryMapViewModel

    init(viewModel: CategoryMapViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        viewModel.createGenericMapView()
            .ignoresSafeArea()
    }
}


#if DEBUG

struct MockCategoryMapView: View {
    var mock: MockContainer
    @State private var category: CategoryUIModel

    var body: some View {
        mock.appContainer.createCategoryMapView(categoryId: category.id)
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
