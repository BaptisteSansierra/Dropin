//
//  MainView.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/7/25.
//

import SwiftUI

struct MainView: View {
    
    // MARK: - Dependencies
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    @Environment(NavigationContext.self) private var navigationContext

    // MARK: - Body
    var body: some View {
        // Bindable
        @Bindable var navigationContext = navigationContext
        
        // Content
        TabView {
            PlacesMapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            PlacesListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
        }
        .accentColor(.dropinSecondary)
        .onAppear {
            locationManager.start()
        }
        .alert("Create a new place",
               isPresented: $navigationContext.showingCreatePlaceMenu,
               actions: {
            Button("Ok") { }
        }) {
            Text("Long press on the map to create a new place!\n\n More ways to be implemented...")
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

#Preview {
    MainView()
        .environment(LocationManager())
        .environment(MapSettings())
        .environment(PlaceFactory.preview)

}
