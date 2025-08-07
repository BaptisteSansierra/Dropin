//
//  RootView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

struct RootView: View {
    
    @Environment(AppNavigationContext.self) var appNavigationContext
    
    //@State var presentSideMenu = false
    //@State var showingSideMenu = false

    var body: some View {

        ZStack {
            //NavigationStack {
                Group {
                    switch appNavigationContext.currentSideMenuContext {
                        case .main:
                            MainView()
                                .navigationTitle("Dropin")
                                .navigationBarTitleDisplayMode(.inline)
                        case .groups:
                            Text("GROUPS")
                        case .tags:
                            Text("TAGS")
                    }
                }
//                .toolbar {
//                    ToolbarItem(placement: .topBarLeading) {
//                        Button("Menu", systemImage: "line.3.horizontal") {
//                            appNavigationContext.showingSideMenu.toggle()
//                        }
//                        .tint(.dropinPrimary)
//                    }
//                    ToolbarItem(placement: .principal) {
//                        HStack {
//                            Text("Dr")
//                                .font(.title)
//                                .fontWeight(.bold)
//                                .padding(0)
//                                .offset(x: 4, y: 0)
//                            DropinLogo(lineWidthMuliplier: 4, pinSizeMuliplier: 1.5)
//                                .frame(width: 25, height: 25)
//                            Text("pin")
//                                .font(.title)
//                                .fontWeight(.bold)
//                                .padding(0)
//                                .offset(x: -4, y: 0)
//                        }
//                    }
//                }
//                .navigationDestination(for: SDPlace.self) { place in
//                    PlaceDetails(place: place)
//                }
//            }
            SideMenuView()
        }
        .onFirstAppear {
            // Make life fun, switch app icon
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                let icon = ["AppIcon", "AppIcon2", "AppIcon3", "AppIcon4"][Int.random(in: 0...3)]
                UIApplication.setApplicationIconWithoutAlert(icon)
            })
        }
    }
}

#Preview {
    RootView()
        .environment(AppNavigationContext())
        .environment(MapSettings())
        .environment(LocationManager())
        .environment(PlaceFactory())
}
