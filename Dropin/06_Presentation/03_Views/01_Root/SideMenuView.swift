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
    init(currentSideMenuContext: Binding<SideMenuContext>) {
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
                HStack {
                    ZStack{
                        Rectangle()
                            .fill(.white)
                            .frame(width: 300)
                            .shadow(color: .black, radius: 5, x: 0, y: 3)
                        content
                            .frame(width: 300)
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
        VStack(spacing: 0) {
            header
                .padding(0)
            Spacer()
                .frame(height: 80)
            
            SideMenuItemView(label: "common.places",
                             systemImage: "globe.europe.africa.fill",
                             context: .main,
                             currentSideMenuContext: $currentSideMenuContext)
                .frame(height: 60)
                .padding(.bottom, 20)
            
            SideMenuItemView(label: "common.groups",
                             systemImage: "folder",
                             context: .groups,
                             currentSideMenuContext: $currentSideMenuContext)
                .frame(height: 60)
                .padding(.bottom, 20)

            SideMenuItemView(label: "common.tags",
                             systemImage: "tag",
                             context: .tags,
                             currentSideMenuContext: $currentSideMenuContext)
                .frame(height: 60)
                .padding(.bottom, 20)

            Spacer()
            
            Rectangle()
                .foregroundStyle(.dropinPrimary)
                .frame(height: 0.5)
            
            Text("developed_by")
                .font(.caption)
                .fontWeight(.regular)
                .padding(.top, 20)
                .padding(.bottom, 10)

            Text("_NOTTR_v\(appVersion)(\(appBuild))")
                .font(.caption2)
                .fontWeight(.light)
                .padding(.bottom, 20)
        }
    }
        
    var header: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.dropinPrimary)
            VStack {
                Spacer()
                    .frame(height: 70)
                HStack(alignment: .center) {
                    ZStack(alignment: .center) {
                        Circle()
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                        DropinLogo(lineWidthMuliplier: 2, pinSizeMuliplier: 1.5)
                            .frame(width: 50, height: 50)
                    }
                    .padding(.leading, 25)
                    .padding(.trailing, 25)
                    
                    Text("Dropin")
                        .foregroundStyle(.white)
                        .font(.largeTitle)

                    Spacer()
                }
                Spacer()
            }
        }
        .frame(height: 160)
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

#if DEBUG

struct MockSideMenuView: View {
    @State var sideMenuContext: SideMenuContext
    @State var navigationContext: NavigationContext
    
    var body: some View {
        SideMenuView(currentSideMenuContext: $sideMenuContext)
            .environment(navigationContext)
    }
    
    init() {
        self.navigationContext = NavigationContext()
        self.sideMenuContext = .main
        
        self.navigationContext.showingSideMenu = true
    }
}

#Preview {
    MockSideMenuView()
}

#endif
