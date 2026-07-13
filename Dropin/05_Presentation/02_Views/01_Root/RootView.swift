//
//  RootView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI
import Combine

struct RootView: View {
    
    /// Handle app shared action
    /// exemple: "Show on map" tapped on a place under "Group detail" view
    ///                  Should trigger actions :
    ///                     1 - Side menu back to main
    ///                     2 - Main view select map tab
    ///                     3 - Map zoom on place
    @Observable final class ActionBus {
        // TODO: at the moment action only concerns Main and it's child
        // should we move it on PlacesView
        enum Action {
            case reloadMainPlaces
            //case updateMapAnnotations
            case selectPlace(placeId: UUID)
            case showOnMap(placeId: UUID)
        }
        
        let actionPublisher = PassthroughSubject<Action, Never>()
        
        func send(_ action: Action) {
            actionPublisher.send(action)
        }
    }

    // MARK: - State & Bindings
    @State private var viewModel: RootViewModel
    @State private var actionBus: ActionBus
    @State private var contentFrameW: CGFloat = .infinity
    @State private var contentFrameH: CGFloat = .infinity
    @State private var contentCornerR: CGFloat = 0
    @State private var contentScale: CGSize = CGSize(width: 1, height: 1)
    
    @State private var menuVisible: Bool = false
    
    // MARK: - init
    init(viewModel: RootViewModel) {
        self.viewModel = viewModel
        self.actionBus = ActionBus()
    }
    
    // MARK: - body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            ZStack {
                currentContentView
                viewModel.createSideMenuView()
            }
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(for: MainNavigationItem.self) { navigationItem in
            resolveDestination(navigationItem: navigationItem)
        }
        // Profile sheet is hosted by RootView (not SideMenuView) — keeps the
        // sheet's presentation host above the side-menu overlay and avoids the
        // "presentation in progress" warning of stacked transient hosts.
        .sheet(isPresented: $viewModel.showingProfileSheet) {
            viewModel.createProfileView()
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(20)
                .presentationBackground(.backgroundPrimary)
                //.presentationBackground(.thinMaterial)
        }
        .task {
            // Make life fun, switch app icon
            Task {
                try await Task.sleep(for: .seconds(1))
                viewModel.switchAppIcon()
            }
        }
        .environment(actionBus)
    }

    @ViewBuilder
    private var currentContentView: some View {
        switch viewModel.appContext.currentSideMenuContext {
            case .main:
                viewModel.createPlacesView()
            case .groups:
                viewModel.createGroupListView()
            case .tags:
                viewModel.createTagListView()
            case .settings:
                viewModel.createSettingsView()
            case .toBeImplemnented:
                NavigationStack {
                    Text(verbatim: "Unavailable")
                    ContentUnavailableView(String(""),
                                           systemImage: "wrench.and.screwdriver")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        DropinToolbar.Burger(showingSideMenu: $viewModel.showingSideMenu)
                    }
                }
        }
    }
    
    @ViewBuilder
    private func resolveDestination(navigationItem: MainNavigationItem) -> some View {
        switch navigationItem {
            case .profile:
                viewModel.createProfileView()
            case .accountDeletion:
                // TODO: push account deletion view here
                EmptyView()
            case .editName:
                // TODO: push edit name here
                EmptyView()
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
}

#endif
