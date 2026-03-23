//
//  MainView.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/7/25.
//

import SwiftUI

struct MainView: View {
    
    // MARK: - States & Bindings
    @State private var viewModel: MainViewModel
    @State private var selectedTab: Int = 0
    @State private var tabViewOffsetY: CGFloat = 0
    @State private var tabViewOpacity: CGFloat = 1
    
    @Binding private var showingSideMenu: Bool
    
    // MARK: - Init
    init(viewModel: MainViewModel, showingSideMenu: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingSideMenu = showingSideMenu
    }
    
    @State private var navBarHeight: CGFloat = 0
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            GeometryReader { proxy in
                ZStack {
                    
                    viewModel.createPlacesMapView()
                        .opacity(selectedTab == 0 ? 1 : 0)
                        .padding(.top, navBarHeight)
                        .padding(.bottom, DropinApp.ui.mainTabBarHeight)
                        .ignoresSafeArea()
                    
                    viewModel.createPlacesListView()
                        .opacity(selectedTab == 1 ? 1 : 0)
                    
                    customTabView
                    
                    // Navigation bar background
                    VStack {
                        Color.backgroundPrimary
                            .frame(height: navBarHeight)
                            .onChange(of: proxy.frame(in: .global)) { oldValue, newValue in
                                navBarHeight = proxy.safeAreaInsets.top
                            }
                            .onAppear {
                                navBarHeight = proxy.safeAreaInsets.top
                            }
                        Spacer()
                    }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            //.toolbarBackground(.backgroundPrimary, for: .navigationBar)
            .toolbar {
                DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
                DropinToolbar.Logo()
                if selectedTab == 0 {
                    DropinToolbar.AddPlace(showingCreatePlaceMenu: $viewModel.showingCreatePlaceMenu)
                } else {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        listTrailingToolbarContent
                    }
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
        }
        .task {
            Task {
                try await viewModel.loadPlaces()
            }
        }
        .accentColor(.dropinSecondary)
    }
    
    // MARK: subviews
    @ViewBuilder
    private var listTrailingToolbarContent: some View {
        Button("common.organize_by_group", systemImage: viewModel.grouped ? "rectangle.3.group.bubble" : "rectangle.3.group.bubble.fill") {
                        viewModel.grouped.toggle()
        }
        .tint(.dropinPrimary)
        Menu("common.sort", systemImage: "arrow.up.arrow.down") {
            Picker("common.sort", selection: $viewModel.sortMode) {
                Text("common.sort.by_distance")
                    .textStyle(.body)
                    .tag(PlacesListViewModel.SortMode.distance)
                Text("common.sort.by_name")
                    .textStyle(.body)
                    .tag(PlacesListViewModel.SortMode.alphabetically)
                Text("common.sort.by_creation_date")
                    .textStyle(.body)
                    .tag(PlacesListViewModel.SortMode.creationDate)
            }
            .pickerStyle(.inline)
        }
        .tint(.dropinPrimary)
    }

    private var customTabView: some View {
        VStack(spacing: 0) {
            Spacer()
            Divider()
            ZStack {
                Rectangle()
                    .frame(height: DropinApp.ui.mainTabBarHeight)
                    //.foregroundStyle(.regularMaterial)
                    .foregroundStyle(.white.opacity(0.35))
                VStack {
                    HStack(alignment: .top) {
                        Button {
                            selectedTab = 0
                        } label: {
                            Spacer()
                            Label {
                                Text("common.map")
                                    .foregroundStyle(selectedTab == 0 ? .dropinSecondary :
                                                        Color(light: Color(rgba: "666666"),
                                                              dark: Color(rgba: "AAAAAA")) )
                            } icon: {
                                Image(systemName: "map")
                                    .foregroundStyle(selectedTab == 0 ? .dropinSecondary :
                                                        Color(light: Color(rgba: "666666"),
                                                              dark: Color(rgba: "AAAAAA")) )
                            }
                            .labelStyle(CenteredLabelStyle())
                            Spacer()
                        }
                        Button {
                            selectedTab = 1
                        } label: {
                            Spacer()
                            Label {
                                Text("common.list")
                                    .foregroundStyle(selectedTab == 1 ? .dropinSecondary :
                                                        Color(light: Color(rgba: "666666"),
                                                              dark: Color(rgba: "AAAAAA")) )
                            } icon: {
                                Image(systemName: "list.bullet")
                                    .foregroundStyle(selectedTab == 1 ? .dropinSecondary :
                                                        Color(light: Color(rgba: "666666"),
                                                              dark: Color(rgba: "AAAAAA")) )
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
        .opacity(tabViewOpacity)
        .offset(y: tabViewOffsetY)
    }

    // MARK: private methods
    /* obsolete TODO: remove
    private func animateTabBar(oldNavigationPath: NavigationPath, newNavigationPath: NavigationPath) {
        if oldNavigationPath.count == 0 && newNavigationPath.count > 0 {
            withAnimation(.easeInOut) {
                tabViewOffsetY = 120
                tabViewOpacity = 0
            }
        } else if oldNavigationPath.count > 0 && newNavigationPath.count == 0 {
            withAnimation(.easeInOut) {
                tabViewOffsetY = 0
                tabViewOpacity = 1
            }
        }
    }
     */

    private func createPlaceEditView(placeId: UUID) -> PlaceEditView {
        guard let index = viewModel.places.firstIndex(where: { $0.id == placeId }) else {
            fatalError("couldn't find any place '\(placeId)' in list")
        }
        return viewModel.createPlaceEditView(place: $viewModel.places[index])
    }

    private func createLookupPlacesView(placeId: UUID) -> LookupPlacesView {
        guard let index = viewModel.places.firstIndex(where: { $0.id == placeId }) else {
            fatalError("couldn't find any place '\(placeId)' in list")
        }
        return viewModel.createLookupPlacesView(place: $viewModel.places[index])
    }

    /*
    private func createPlaceDetailsView(_ placeId: String) -> PlaceDetailsView {
        guard let index = viewModel.places.firstIndex(where: { $0.id == placeId }) else {
            fatalError("couldn't find any place '\(placeId)' in list")
        }
        return viewModel.createPlaceDetailsView(place: $viewModel.places[index], editMode: .none)
    }

    private func createPlaceDetailsView(_ place: PlaceEntity) -> PlaceDetailsView {
        guard let index = viewModel.places.firstIndex(where: { $0.id == place.id }) else {
            fatalError("couldn't find any place named '\(place.name)' in list")
        }
        return viewModel.createPlaceDetailsView(place: $viewModel.places[index], editMode: .none)
    }
     */
    
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
            case .dropAPin:
                viewModel.createDropAPinView()
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
}

private struct CenteredLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center, spacing: 0) {
            configuration.icon
                .font(.subheadlineRegular)
                .frame(height: 15)
                .padding(.bottom, 5)
            configuration.title
                .font(.footnoteRegular)
        }
    }
}

#if DEBUG
struct MockMainView: View {
    @State private var showingSideMenu: Bool = false
    var mock: MockContainer

    var body: some View {
        mock.appContainer.createMainView(showingSideMenu: $showingSideMenu)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
}

#Preview {
    MockMainView()
}

#endif
