//
//  SideMenuView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

struct SideMenuView: View {
    
    //@Binding var isShowing: Bool
    @Environment(AppNavigationContext.self) var appNavigationContext

    var edgeTransition: AnyTransition = .move(edge: .leading)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if appNavigationContext.showingSideMenu {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        appNavigationContext.showingSideMenu.toggle()
                    }
                
                HStack {
                    ZStack{
                        Rectangle()
                            .fill(.white)
                            .frame(width: 270)
                            .shadow(color: .black, radius: 5, x: 0, y: 3)

                        SideMenuContentView()
                            .padding(.top, 100)
                            .frame(width: 270)
                            .background(.white)
                    }
                    .background(.clear)
                    Spacer()
                }
                .background(.clear)
                .transition(edgeTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
        .animation(.easeInOut, value: appNavigationContext.showingSideMenu)
    }
}


struct SideMenuContentView: View {
    
    @Environment(AppNavigationContext.self) var appNavigationContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "face.smiling")
            Text("Content")

            Spacer()

            Button("SET ICON 1") {
                UIApplication.setApplicationIconWithoutAlert("AppIcon3")

//                UIApplication.shared.setAlternateIconName("AppIcon1") { error in
//                    if let error = error {
//                        print("Error setting alternate icon \(error.localizedDescription)")
//                    }
//                }
            }
            Button("SET ICON 2") {
                UIApplication.setApplicationIconWithoutAlert("AppIcon2")

//                UIApplication.shared.setAlternateIconName("AppIcon2") { error in
//                    if let error = error {
//                        print("Error setting alternate icon \(error.localizedDescription)")
//                    }
//                }
            }


            Divider()
            Image(systemName: "globe.europe.africa.fill")
                .onTapGesture {
                    appNavigationContext.currentSideMenuContext = .main
                    appNavigationContext.showingSideMenu = false
                }
            Divider()
            Image(systemName: "folder")
                .onTapGesture {
                    appNavigationContext.currentSideMenuContext = .groups
                    appNavigationContext.showingSideMenu = false
                }
            Divider()
            Image(systemName: "tag")
                .onTapGesture {
                    appNavigationContext.currentSideMenuContext = .tags
                    appNavigationContext.showingSideMenu = false
                }
            
            Spacer()

        }
        .padding(.top, 100)
    }
}
