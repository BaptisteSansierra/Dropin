//
//  RootView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

struct RootView: View {
    
    // MARK: - Dependencies
    @Environment(AppNavigationContext.self) var appNavigationContext
    
    // MARK: - body
    var body: some View {
        ZStack {
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
