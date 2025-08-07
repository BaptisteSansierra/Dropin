//
//  MainView.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/7/25.
//

import SwiftUI

struct MainView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    @Environment(AppNavigationContext.self) private var navigationContext

    //@State private var showingPlusMenu = false

    var body: some View {
        
        @Bindable var navigationContext = navigationContext
        
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
//            .toolbar {
//                ToolbarItem(placement: .topBarLeading) {
//                    Button("Menu", systemImage: "line.3.horizontal") {
//                        showingSideMenu.toggle()
//                    }
//                    .tint(.dropinPrimary)
//                }
//                ToolbarItem(placement: .topBarTrailing) {
//                    HStack {
//                        Button("Add", systemImage: "plus") {
//                            showingPlusMenu.toggle()
//                        }
//                        .tint(.dropinPrimary)
//                    }
//                }
//
//            }
        //}
        .onAppear {
            locationManager.start()
        }
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
    }
}

#Preview {
    MainView()
        .environment(LocationManager())
        .environment(MapSettings())
        .environment(PlaceFactory.preview)

}
