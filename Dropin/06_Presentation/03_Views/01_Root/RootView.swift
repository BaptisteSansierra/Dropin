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
    @State private var contentFrameW: CGFloat = .infinity
    @State private var contentFrameH: CGFloat = .infinity
    @State private var contentCornerR: CGFloat = 0
    @State private var contentScale: CGSize = CGSize(width: 1, height: 1)
    
    @State private var menuVisible: Bool = false

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
                        viewModel.createGroupListView()
                    case .tags:
                        viewModel.createTagListView()
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

#if DEBUG
struct MockRootView: View {
    var mock: MockContainer

    var body: some View {
        mock.appContainer.createRootView()
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
}

#Preview {
    MockRootView()
        .environment(LocationManager())
        .environment(MapSettings())
        .environment(NavigationContext())
}

#endif
