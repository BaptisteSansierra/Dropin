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
        @Bindable var navigationContext = navigationContext
        
        ZStack {
            viewModel.createPlacesMapView()
                .opacity(selectedTab == 0 ? 1 : 0)
            
            viewModel.createPlacesListView()
                .opacity(selectedTab == 1 ? 1 : 0)
            
            customTabView
        }
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
        .onChange(of: navigationContext.navigationPath) { oldValue, newValue in
            animateTabBar(oldNavigationPath: oldValue, newNavigationPath: newValue)
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
