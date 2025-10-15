//
//  RootView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

struct RootView: View {

    // MARK: - State & Bindings
    @State private var viewModel: RootViewModel

    // MARK: - Dependencies
    @Environment(NavigationContext.self) var navigationContext
    
    // MARK: - init
    init(viewModel: RootViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - body
    var body: some View {
        ZStack {
            Group {
                switch viewModel.currentSideMenuContext {
                    case .main:
                        viewModel.createMainView()
                    case .groups:
                        Text("Groups")
                        //GroupListView()
                    case .tags:
                        DummyTagView()
                        //TagListView()
                }
            }
            SideMenuView(currentSideMenuContext: $viewModel.currentSideMenuContext)
        }
        .task {
            // Make life fun, switch app icon
            Task {
                try await Task.sleep(for: .seconds(1))
                viewModel.switchAppIcon()
            }
        }
    }
}

#Preview {
    AppContainer.mock().createRootView()
        .environment(NavigationContext())
        .environment(MapSettings())
}
