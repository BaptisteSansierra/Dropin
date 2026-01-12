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
    @State private var toolbarContents: [Int: CustomToolbarContent] = [:]
    @State private var selectedTab: Int = 0
    @State private var tabViewOffsetY: CGFloat = 0
    @State private var tabViewOpacity: CGFloat = 1
    
    // MARK: - Dependencies
    @Environment(NavigationContext.self) private var navigationContext

    // MARK: - Properties
    private var currentToolbar: CustomToolbarContent? {
        toolbarContents[selectedTab]
    }
    
    // MARK: - Init
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    var body: some View {
        //@Bindable var navigationContext = navigationContext
        
        NavigationStack(path: $viewModel.coordinator.path) {
            
            ZStack {
                viewModel.createPlacesMapView()
                    .opacity(selectedTab == 0 ? 1 : 0)
                
                viewModel.createPlacesListView()
                    .opacity(selectedTab == 1 ? 1 : 0)

                customTabView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.white, for: .navigationBar)
            .toolbar {
                DropinToolbar.Burger()
                DropinToolbar.Logo()
                if selectedTab == 0 {
                    DropinToolbar.AddPlace()
                } else {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        listTrailingToolbarContent
                    }
                }
            }
            .navigationDestination(for: NavigationItem.self) { navigationItem in
                resolveDestination(navigationItem: navigationItem)
            }

            
            // TODO: to be removed
//            .navigationDestination(for: PlaceEntity.self) { place in
//                // TODO: to be removed following func
//                createPlaceDetailsView(place)
//            }
        }
        .task {
            Task {
                try await viewModel.loadPlaces()
            }
        }
        .accentColor(.dropinSecondary)
        .onChange(of: navigationContext.navigationPath) { oldValue, newValue in
            animateTabBar(oldNavigationPath: oldValue, newNavigationPath: newValue)
        }
    }
    
    // MARK: subviews
//    var currentView: some View {
//        Group {
//            if selectedTab == 0 {
//                viewModel.createPlacesMapView()
//            } else {
//                viewModel.createPlacesListView()
//            }
//        }
//    }

    @ViewBuilder
    private var listTrailingToolbarContent: some View {
        Button("common.organize_by_group", systemImage: viewModel.grouped ? "rectangle.3.group.bubble" : "rectangle.3.group.bubble.fill") {
                        viewModel.grouped.toggle()
        }
        .tint(.dropinPrimary)
        Menu("common.sort", systemImage: "arrow.up.arrow.down") {
            Picker("common.sort", selection: $viewModel.sortMode) {
                Text("common.sort.by_distance")
                    .tag(PlacesListViewModel.SortMode.distance)
                Text("common.sort.by_name")
                    .tag(PlacesListViewModel.SortMode.alphabetically)
                Text("common.sort.by_creation_date")
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
                    .frame(height: 80)
                    .foregroundStyle(.regularMaterial)
                VStack {
                    HStack(alignment: .top) {
                        Button {
                            selectedTab = 0
                        } label: {
                            Spacer()
                            Label {
                                Text("common.map")
                                    .foregroundStyle(selectedTab == 0 ? .dropinSecondary : Color(rgba: "666666"))
                            } icon: {
                                Image(systemName: "map")
                                    .foregroundStyle(selectedTab == 0 ? .dropinSecondary : Color(rgba: "666666"))
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
                                    .foregroundStyle(selectedTab == 1 ? .dropinSecondary : Color(rgba: "666666"))
                            } icon: {
                                Image(systemName: "list.bullet")
                                    .foregroundStyle(selectedTab == 1 ? .dropinSecondary : Color(rgba: "666666"))
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
    
    @ViewBuilder
    private func resolveDestination(navigationItem: NavigationItem) -> some View {
        switch navigationItem {
            case .placeDetailsView(let placeID, _):
                createPlaceDetailsView(placeID)
            case .lookupPlacesView:
                viewModel.createLookupPlacesView()
            case .undefinedDummyView:
                ZStack {
                    Color.orange
                    Text("To be implemented...")
                }
            default:
                ZStack {
                    Color.orange
                    Text("Undefined navigation item")
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
                .font(.subheadline)
                .frame(height: 15)
                //.border(.red, width: 1)
                .padding(.bottom, 5)
            configuration.title
                .font(.footnote)
        }
    }
}

#if DEBUG
struct MockMainView: View {
    var mock: MockContainer

    var body: some View {
        mock.appContainer.createMainView()
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
}

#Preview {
    MockMainView()
        .environment(LocationManager())
        .environment(MapSettings())
        .environment(NavigationContext())
}

#endif
