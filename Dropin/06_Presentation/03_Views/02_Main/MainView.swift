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
//    @State private var toolbarItems: [ToolbarPreferenceItem] = [ToolbarPreferenceItem]()
    @State private var toolbarContent: CustomToolbarContent?

    // MARK: - Dependencies
    //@Environment(\.modelContext) private var modelContext
    //@Environment(LocationManager.self) private var locationManager
    @Environment(NavigationContext.self) private var navigationContext

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    var body: some View {
        // Bindable
        @Bindable var navigationContext = navigationContext
        
        // Content
        NavigationStack(path: $navigationContext.navigationPath) {
            TabView {
                viewModel.createPlacesMapView()
                    .tabItem {
                        Label("common.map", systemImage: "map")
                    }
                viewModel.createPlacesListView()
                    .tabItem {
                        Label("common.list", systemImage: "list.bullet")
                    }
                
            }
            .navigationDestination(for: PlaceEntity.self) { place in
                createPlaceDetailsView(place)
            }
            .navigationBarTitleDisplayMode(.inline)
            
            .onPreferenceChange(ToolbarContentPreference.self) { content in
                toolbarContent = content
            }
            .toolbar {
                // Custom title view
                if let titleView = toolbarContent?.titleView {
                    ToolbarItem(placement: .principal) {
                        titleView
                    }
                }
                
                // Leading items
                ToolbarItemGroup(placement: .topBarLeading) {
                    if let leading = toolbarContent?.leading {
                        ForEach(leading) { item in
                            item.content
                        }
                    }
                }
                
                // Trailing items
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if let trailing = toolbarContent?.trailing {
                        ForEach(trailing) { item in
                            item.content
                        }
                    }
                }
            }
            /*
            .toolbar {
                DropinToolbar.Logo()
                DropinToolbar.Burger()
                
                // TODO: find a way to loop on toolbarItems here :(
            }

            
            .toolbar(content: {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    //                    Button(action: {}, label: {Text("111")})
                    Button(action: {}, label: {Text("222")})
//                    ForEach(toolbarItems) { item in
//                        //item.content
//                        Button(action: {}, label: {Text("\(item.id)")})
//
//                    }
                }
             */
//        })

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
//        .onPreferenceChange(ToolbarPreferenceKey.self) { value in
//            toolbarItems = value
//        }
//            ToolbarItemGroup {
//                ForEach(toolbarItems) { item in
//                    ToolbarItem(placement: item.placement) {
//                        Text("Aaa")
//                    }
//                }
//            }
            
//            Group {
//                ForEach(toolbarItems) { item in
//                    ToolbarItem(placement: item.placement) {
//                        Text("Aaa")
//                    }
//                }
//            }
            
            
////                ToolbarItem(placement: item.placement) {
////                    AnyView(item.content)
////                }
//            }

        
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
