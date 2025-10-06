//
//  RootView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//
#if false

import SwiftUI

struct RootView: View {
    
    // MARK: - Dependencies
    @Environment(NavigationContext.self) var navigationContext
    
    // MARK: - body
    var body: some View {
        ZStack {
            Group {
                switch navigationContext.currentSideMenuContext {
                    case .main:
                        MainView()
                    case .groups:
                        GroupListView()
                    case .tags:
                        TagListView()
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
        .environment(NavigationContext())
        .environment(MapSettings())
        .environment(LocationManager())
        .environment(PlaceFactory())
}
#endif

