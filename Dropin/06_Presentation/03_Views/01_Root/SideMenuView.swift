//
//  SideMenuView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

struct SideMenuView: View {
    
    // MARK: - States & Bindings
    @Binding var currentSideMenuContext: SideMenuContext

    // MARK: - Dependencies
    @Environment(NavigationContext.self) var navigationContext

    // MARK: - private properties
    private var appVersion: String = ""
    private var appBuild: String = ""
    private var edgeTransition: AnyTransition = .move(edge: .leading)

    // MARK: - init
    init(currentSideMenuContext: Binding<SideMenuContext>/*, showingSideMenu: Binding<Bool>*/ ) {
        self._currentSideMenuContext = currentSideMenuContext
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            appVersion = version
        }
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            appBuild = build
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            if navigationContext.showingSideMenu {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        navigationContext.showingSideMenu.toggle()
                    }
                HStack {
                    ZStack{
                        Rectangle()
                            .fill(.white)
                            .frame(width: 270)
                            .shadow(color: .black, radius: 5, x: 0, y: 3)
                        content
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
        .gesture(leftSwipeGesture)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
        .animation(.easeInOut, value: navigationContext.showingSideMenu)
    }
    
    // MARK: - Subviews
    var content: some View {
        VStack() {
            HStack {
                ZStack(alignment: .center) {
                    Circle()
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                    DropinLogo(lineWidthMuliplier: 2, pinSizeMuliplier: 1.5)
                        .frame(width: 50, height: 50)
                }
                .padding(.top, 70)
                .padding(.leading, 25)
                .padding(.bottom, 25)
                Spacer()
            }
            SideMenuItemView(label: "common.places",
                             systemImage: "globe.europe.africa.fill",
                             context: .main,
                             currentSideMenuContext: $currentSideMenuContext)
            SideMenuItemView(label: "common.groups",
                             systemImage: "folder",
                             context: .groups,
                             currentSideMenuContext: $currentSideMenuContext)
            SideMenuItemView(label: "common.tags",
                             systemImage: "tag",
                             context: .tags,
                             currentSideMenuContext: $currentSideMenuContext)
            Spacer()
            HStack {
                Text("_NOTTR_v\(appVersion)(\(appBuild))")
                    .padding()
                    .font(.caption)
                    .fontWeight(.black)
            }
            .padding(.bottom, 30)
        }
        .background {
            LinearGradient(gradient: Gradient(colors: [.dropinPrimary.darken(factor: 0.1),
                                                       .dropinPrimary,
                                                       .dropinPrimary.lighten(factor: 0.1),
                                                       .dropinPrimary.lighten(factor: 0.2),
                                                       .dropinPrimary.lighten(factor: 0.9)]),
                           startPoint: .top,
                           endPoint: .bottom)
        }
    }

    // MARK: - Gestures
    private var leftSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global).onEnded { value in
            let horizontalAmount = value.translation.width
            let verticalAmount = value.translation.height
            guard abs(horizontalAmount) > abs(verticalAmount) && horizontalAmount < 0 else { return }
            navigationContext.showingSideMenu = false
        }
    }
}
