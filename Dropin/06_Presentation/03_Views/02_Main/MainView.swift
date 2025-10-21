//
//  MainView.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/7/25.
//

import SwiftUI

struct CenteredLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center, spacing: 7) {
            configuration.icon
                .font(.title)
                .frame(height: 40)
                //.border(.red, width: 1)
            configuration.title
                .font(.footnote)
        }
    }
}

struct MainView: View {
    
    // MARK: - States & Bindings
    @State private var viewModel: MainViewModel
    @State private var toolbarContents: [Int: CustomToolbarContent] = [:]
    @State private var selectedTab: Int = 0

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
        // Bindable
        @Bindable var navigationContext = navigationContext
        
        // Content
        NavigationStack(path: $navigationContext.navigationPath) {
            
            /*
            ZStack {
                
                //currentView
                
                viewModel.createPlacesMapView()
                    .opacity(selectedTab == 0 ? 1 : 0)

                viewModel.createPlacesListView()
                    .opacity(selectedTab == 1 ? 1 : 0)

                
                // custom tabs
                VStack(spacing: 0) {
                    Spacer()
                    Divider()
                    ZStack {
                        Rectangle()
                            .frame(height: 180)
                            .foregroundStyle(.regularMaterial)
                        HStack(alignment: .top) {
                            Button {
                                selectedTab = 0
                                //navigationContext.searchBarPresented = false
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
                                //navigationContext.searchBarPresented = true
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
                    }
                }
                .ignoresSafeArea()
            }
            
             */
            
            TabView(selection: $selectedTab) {
                viewModel.createPlacesMapView()
                    .tabItem {
                        Label("common.map", systemImage: "map")
                    }
                    .tag(0)
                viewModel.createPlacesListView()
                    .tabItem {
                        Label("common.list", systemImage: "list.bullet")
                    }
                    .tag(1)
            }
            
            
            .navigationDestination(for: PlaceEntity.self) { place in
                createPlaceDetailsView(place)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onPreferenceChange(ToolbarContentPreference.self) { content in
                guard let content = content else { return }
                toolbarContents[content.tabIndex] = content
            }
            .toolbar {
                // Custom title view
                if let titleView = currentToolbar?.title {
                    ToolbarItem(placement: .principal) {
                        titleView
                    }
                }
                // Leading items
                if let leading = currentToolbar?.leading {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        leading
                    }
                }
                // Trailing items
                if let trailing = currentToolbar?.trailing {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        trailing
                    }
                }
            }
        }
        .toolbar(.visible, for: .tabBar)

        .task {
            Task {
                try await viewModel.loadPlaces()
            }
        }
        .accentColor(.dropinSecondary)
        .alert("common.create_place",
               isPresented: $navigationContext.showingCreatePlaceMenu,
               actions: {
            Button("common.ok") { }
        }) {
            Text("_TEMP_long_press_instructions")
        }
        /*
        .confirmationDialog("Save a location", isPresented: $navigationContext.showingCreatePlaceMenu, titleVisibility: .visible) {
            Button("From your current position") {
                
            }
            Button("Drop a pin") {
                
            }
            Button("Provide an address") {
                // https://developer.apple.com/documentation/applemapsserverapi/-v1-searchautocomplete
            }
            Button("Provide coordinates") {
                //
            }
            Button("From image library") {
                //
            }
            Button("RANDOM COORDS") {
                guard let loc = locationManager.lastKnownLocation else {
                    print("Unknown loc")
                    return
                }
                let latitude = loc.latitude + Double.random(in: -0.02...0.01)
                let longitude = loc.longitude + Double.random(in: -0.02...0.01)
                let item = SDPlace(name: "random\(Int.random(in: 100...999))", latitude: latitude, longitude: longitude, address: "")
                modelContext.insert(item)
            }
        }
         */
    }
    
//    func toolbarContentItem(item: ToolbarPreferenceItem) -> ToolbarItem<Any, View> {
//        ToolbarItem(placement: item.placement) {
//            Text("Aaa")
//        }
//    }
//    
//    var toolbarContent: some ToolbarContent {
//        ForEach(toolbarItems) { item in
//            ToolbarItem(placement: item.placement) {
//                Text("Aaa")
//            }
//        }
//    }

    // MARK: subviews
    var currentView: some View {
        Group {
            if selectedTab == 0 {
                viewModel.createPlacesMapView()
            } else {
                viewModel.createPlacesListView()
            }
        }
    }

    
    // MARK: private methods
    private func createPlaceDetailsView(_ place: PlaceEntity) -> PlaceDetailsView {
        guard let index = viewModel.places.firstIndex(where: { $0.id == place.id }) else {
            fatalError("couldn't find any place named '\(place.name)' in list")
        }
        return viewModel.createPlaceDetailsView(place: $viewModel.places[index], editMode: .none)
    }
}

//struct DynamicToolbar: ToolbarContent {
//    let items: [ToolbarPreferenceItem]
//    
//    var body: some ToolbarContent {
////        ForEach(items, id: \.id) { item in
//        ForEach(Array(items.enumerated()), id: \.element.id) { _, item in
//
//            ToolbarItem(placement: item.placement) {
//                AnyView(item.content)
//                //Text("Pipo")
//            }
//        }
//    }
//    
//    @ToolbarContentBuilder
//    private func ForEachToolbarItems(_ items: [ToolbarPreferenceItem]) -> some ToolbarContent {
//        for item in items {
//            ToolbarItem(placement: item.placement) {
//                item.content
//            }
//        }
//    }
//}

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
