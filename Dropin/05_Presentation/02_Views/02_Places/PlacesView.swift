//
//  PlacesView.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/7/25.
//

import SwiftUI

struct PlacesView: View {
        
    // MARK: - States & Bindings
    @State private var viewModel: PlacesViewModel
    @Binding private var showingSideMenu: Bool
    @Environment(RootView.ActionBus.self) private var actionBus

    // MARK: - Init
    init(viewModel: PlacesViewModel, showingSideMenu: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingSideMenu = showingSideMenu
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            GeometryReader { proxy in
                ZStack {
                    viewModel.createPlacesMapView(navBarHeight: viewModel.navBarHeight)
                        .opacity(viewModel.selectedTab == 0 ? 1 : 0)
                        .ignoresSafeArea()
                    
                    viewModel.createPlacesListView()
                        .opacity(viewModel.selectedTab == 1 ? 1 : 0)
                    
                    customTabView
                    
                    // Navigation bar background
                    VStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .frame(height: viewModel.navBarHeight)
                            .onChange(of: proxy.frame(in: .global)) { oldValue, newValue in
                                viewModel.navBarHeight = proxy.safeAreaInsets.top
                            }
                            .onAppear {
                                viewModel.navBarHeight = proxy.safeAreaInsets.top
                            }
                            .background(.thinMaterial)
                        Spacer()
                    }
                    .ignoresSafeArea(edges: .top)
                }
                .overlay(alignment: .top) {
                    syncingView
                        .animation(.easeInOut(duration: 0.3), value: viewModel.syncStatus.isSyncing)
                }
                .onAppear {
                    onAppearCallback()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
                DropinToolbar.Logo()
                ToolbarItemGroup(placement: .topBarTrailing) {
                    trailingToolbarContent
                        .tint(.dropinPrimary)
                }
            }
            .navigationDestination(for: NavigationItem.self) { navigationItem in
                resolveDestination(navigationItem: navigationItem)
            }
            .onChange(of: showingSideMenu) { _, newValue in
                guard newValue else { return }
                // Hide sheet overlays if any
                viewModel.isPresenting = true
            }
            .onChange(of: viewModel.showingCreatePlaceMenu) { _, newValue in
                guard newValue else { return }
                // Hide sheet overlays if any
                viewModel.isPresenting = true
            }
            .onChange(of: viewModel.syncStatus.lastSyncedAt) {
                Task {
                    await reloadPlaces()
                }
            }
        }
        .onReceive(actionBus.actionPublisher) { handleAction($0) }
        .task {
            Task {
                try await viewModel.loadPlaces()
            }
        }
        .accentColor(.dropinSecondary)
        // Filtering sheet
        .sheet(isPresented: $viewModel.showingFilter) {
            viewModel.createPlaceFilterView()
        }
        // Selected place sheet
        .sheet(item: $viewModel.selectedPlaceId,
               onDismiss: {
            viewModel.selectedPlaceId = nil
            viewModel.detailSheetDetent = .medium
        }) { placeId in
            createPlaceDetailsSheetView()
                .presentationDetents([.medium, .large], selection: $viewModel.detailSheetDetent)
                .presentationCornerRadius(20)
                .presentationBackground(.backgroundPrimary)
        }
    }
    
    // MARK: subviews
    @ViewBuilder
    private var trailingToolbarContent: some View {
        if viewModel.selectedTab == 0 {
            
            /*
            Button(String("TEST"),
                   systemImage: "arrow.clockwise.circle") {
                viewModel.mapReloadGen += 1
            }
            .accentColor(.red)
            */
            
            Button("common.organize_by_group",
                   systemImage: viewModel.currentFilter == nil ?
                     "line.3.horizontal.decrease.circle" :
                     "line.3.horizontal.decrease.circle.fill") {
                viewModel.showingFilter.toggle()
            }
            AddPlaceToolbarView(showingCreatePlaceMenu: $viewModel.showingCreatePlaceMenu)
        } else {
            Button("common.organize_by_group",
                   systemImage: viewModel.currentFilter == nil ?
                     "line.3.horizontal.decrease.circle" :
                     "line.3.horizontal.decrease.circle.fill") {
                viewModel.showingFilter.toggle()
            }
            Menu("common.sort", systemImage: "arrow.up.arrow.down") {
                Picker("common.sort", selection: $viewModel.sortPolicy) {
                    Text("common.sort.by_distance")
                        .textStyle(.body)
                        .tag(PlaceSortPolicy.distance)
                    Text("common.sort.by_name")
                        .textStyle(.body)
                        .tag(PlaceSortPolicy.alphabetically)
                    Text("common.sort.by_creation_date")
                        .textStyle(.body)
                        .tag(PlaceSortPolicy.createdAt)
                }
                .pickerStyle(.inline)
            }
        }
    }

    private var customTabView: some View {
        VStack(spacing: 0) {
            Spacer()
            Divider()
            ZStack {
                Rectangle()
                    .frame(height: DropinApp.ui.mainTabBarHeight)
                    .foregroundStyle(.ultraThinMaterial)
                    //.foregroundStyle(.white.opacity(0.35))
                VStack {
                    let unselectedColor = Color.shade5
                    //let unselectedColor = Color(light: Color(rgba: "666666"),
                    //                            dark: Color(rgba: "AAAAAA"))

                    HStack(alignment: .top) {
                        Button {
                            viewModel.selectedTab = 0
                        } label: {
                            let color = viewModel.selectedTab == 0 ? .dropinPrimary : unselectedColor
                            Spacer()
                            Label {
                                Text("common.map")
                                    .textStyle(.tabBarTxt, color: color)
                            } icon: {
                                Image(systemName: "map")
                                    .textStyle(.tabBarImg, color: color)
                            }
                            .labelStyle(CenteredLabelStyle())
                            Spacer()
                        }
                        Button {
                            viewModel.selectedTab = 1
                        } label: {
                            let color = viewModel.selectedTab == 1 ? .dropinPrimary : unselectedColor
                            Spacer()
                            Label {
                                Text("common.list")
                                    .textStyle(.tabBarTxt, color: color)
                            } icon: {
                                Image(systemName: "list.bullet")
                                    .textStyle(.tabBarImg, color: color)
                            }
                            .labelStyle(CenteredLabelStyle())
                            Spacer()
                        }
                        
                    }
                    Spacer()
                        .frame(height: 15)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var syncingView: some View {
        if viewModel.syncStatus.isSyncing {
            /*
            if !viewModel.reachabilityService.isConnected {
                Text("common.offline")
                    .foregroundStyle(.white)
                    .textStyle(.caption2)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .phaseAnimator([0.15, 0.5]) { view, opacity in
                        view.opacity(opacity)
                    } animation: { _ in
                            .linear(duration: 0.5)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.destructive)
                    }
                    .padding(.top)
                    .transition(.opacity)
            } else {
             */
                Text("main.syncing")
                    .textStyle(.caption2)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .phaseAnimator([0.15, 0.5]) { view, opacity in
                        view.opacity(opacity)
                    } animation: { _ in
                            .linear(duration: 0.5)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                    }
                    .padding(.top)
                    .transition(.opacity)
            //}
        }
    }

    // MARK: private methods
    private func createPlaceEditView(placeId: UUID) -> PlaceEditView {
        guard let index = viewModel.places.firstIndex(where: { $0.id == placeId }) else {
            fatalError("couldn't find any place '\(placeId)' in list")
        }
        return viewModel.createPlaceEditView(place: viewModel.places[index])
    }

    private func createLookupPlacesView(placeId: UUID) -> LookupPlacesView {
        guard let index = viewModel.places.firstIndex(where: { $0.id == placeId }) else {
            fatalError("couldn't find any place '\(placeId)' in list")
        }
        return viewModel.createLookupPlacesView(place: $viewModel.places[index])
    }
    
    @ViewBuilder
    private func resolveDestination(navigationItem: NavigationItem) -> some View {
        switch navigationItem {
            case .placeEditView(let placeId):
                createPlaceEditView(placeId: placeId)
            case .lookupPlacesView:
                viewModel.createLookupPlacesView()
            case .lookupPlacesEditView(let placeId):
                createLookupPlacesView(placeId: placeId)
            case .placeCreateView(let coordinates, let address, let name, let marker, let tags, let group):
                viewModel.createPlaceCreateView(coordinates: coordinates,
                                                address: address,
                                                name: name,
                                                marker: marker,
                                                tags: tags,
                                                group: group)
            // development cases
            case .undefinedDummyView:
                ZStack {
                    Color.orange
                    Text(verbatim: "To be implemented...")
                }
            default:
                ZStack {
                    Color.orange
                    Text(verbatim: "Undefined navigation item")
                }
                .onAppear {
                    assertionFailure("undefined navigation item \(navigationItem)")
                }
        }
    }
    
    private func onAppearCallback() {
        /*
        guard let lastNavigationSource = viewModel.coordinator.lastNavigationSource else {
            return
        }
        switch lastNavigationSource {
            case .placeCreateView, .placeEditView:
                Task {
                    await reloadPlaces()
                }
            default:
                print("ignore lastNavigationSource = \(lastNavigationSource)")
                ()
        }
         */
    }
    
    private func reloadPlaces() async {
        do {
            try await viewModel.loadPlaces()
        } catch {
            assertionFailure("couldn't reload places")
        }
    }
    
    private func handleAction(_ action: RootView.ActionBus.Action) {
        switch action {
            case .showOnMap:
                viewModel.selectedTab = 0
            case .reloadMainPlaces:
                Task {
                    try? await viewModel.loadPlaces()
                }
//            case .updateMapAnnotations:
//                Task {
//                    viewModel.updateMapAnnotations()
//                }
            default:
                ()
        }
    }
}

// Create Views
extension PlacesView {
    
    private func createPlaceDetailsSheetView() -> PlaceSheetView {
        guard let selectedPlaceId = viewModel.selectedPlaceId else {
            fatalError("selectedPlaceId undefined")
        }
        guard let index = viewModel.places.firstIndex(where: { $0.id == selectedPlaceId }) else {
            fatalError("couldn't find place with id \(selectedPlaceId)")
        }
        return viewModel.createPlaceSheetView(place: $viewModel.places[index],
                                              detent: $viewModel.detailSheetDetent)
    }
}

#if DEBUG
struct MockPlacesView: View {
    @State private var showingSideMenu: Bool = false
    var mock: MockContainer

    var body: some View {
        mock.appContainer.createPlacesView(showingSideMenu: $showingSideMenu)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
}

#Preview {
    MockPlacesView()
}

#endif

