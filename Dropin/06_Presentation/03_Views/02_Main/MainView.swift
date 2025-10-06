//
//  MainView.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/7/25.
//

import SwiftUI

struct MainView: View {
    
    // MARK: - Properties
    private var viewModel: MainViewModel

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
        TabView {
            viewModel.createPlacesMapView()
                .tabItem {
                    Label("common.map", systemImage: "map")
                }
            Text("LIST")
//                viewModel.createPlacesListView()
//                .tabItem {
//                    Label("common.list", systemImage: "list.bullet")
//                }
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
}

#if DEBUG
#Preview {
    AppContainer.mock().createMainView()
        .environment(LocationManager())
        .environment(MapSettings())
}
#endif
