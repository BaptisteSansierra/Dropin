//
//  SideMenuView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

struct SideMenuView: View {
    
    // MARK: - States & Bindings
    @Binding private var showingSideMenu: Bool
    @Binding private var currentSideMenuContext: SideMenuContext
    @State private var logoVariant: DropinLogo.Variant = .logo

    // MARK: - private properties
    private var appVersion: String = ""
    private var appBuild: String = ""
    private var edgeTransition: AnyTransition = .move(edge: .leading)

    // MARK: - init
    init(showingSideMenu: Binding<Bool>,
         currentSideMenuContext: Binding<SideMenuContext>) {
        self._showingSideMenu = showingSideMenu
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
            if showingSideMenu {
                Color.overlayAlphaLayer
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingSideMenu = false
                    }
                HStack {
                    ZStack{
                        Rectangle()
                            .fill(.backgroundPrimary)
                            .frame(minWidth: 300, maxWidth: 340)
                            .shadow(color: .textPrimary, radius: 5, x: 0, y: 3)
                        content
                            .frame(minWidth: 300, maxWidth: 340)
                            .background(.backgroundPrimary)
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
        .animation(.easeInOut, value: showingSideMenu)
    }
    
    // MARK: - Subviews
    var content: some View {
        VStack(spacing: 0) {
            header
                .padding(0)
//            Spacer()
//                .frame(height: 80)
            
            SideMenuItemView(label: "common.places",
                             systemImage: "globe.europe.africa.fill",
                             context: .main,
                             showingSideMenu: $showingSideMenu,
                             currentSideMenuContext: $currentSideMenuContext)
                .frame(height: 60)
                .padding(.bottom, 0)
            
            SideMenuItemView(label: "common.groups",
                             systemImage: "folder",
                             context: .groups,
                             showingSideMenu: $showingSideMenu,
                             currentSideMenuContext: $currentSideMenuContext)
                .frame(height: 60)
                .padding(.bottom, 0)

            SideMenuItemView(label: "common.tags",
                             systemImage: "slider.horizontal.3",
                             context: .tags,
                             showingSideMenu: $showingSideMenu,
                             currentSideMenuContext: $currentSideMenuContext)
                .frame(height: 60)
                .padding(.bottom, 0)
            
            Divider()
                .padding(.vertical, 5)
            
            SideMenuItemView(label: "common.favorites",
                             systemImage: "star",
                             context: .toBeImplemnented,
                             showingSideMenu: $showingSideMenu,
                             currentSideMenuContext: $currentSideMenuContext)
                .frame(height: 60)
                .padding(.bottom, 0)
            SideMenuItemView(label: "common.recents",
                             systemImage: "clock",
                             context: .toBeImplemnented,
                             showingSideMenu: $showingSideMenu,
                             currentSideMenuContext: $currentSideMenuContext)
                .frame(height: 60)
                .padding(.bottom, 0)

            Divider()
                .padding(.vertical, 5)
            
            SideMenuItemView(label: "common.settings",
                             systemImage: "slider.horizontal.3",
                             context: .toBeImplemnented,
                             showingSideMenu: $showingSideMenu,
                             currentSideMenuContext: $currentSideMenuContext)
                .frame(height: 60)
                .padding(.bottom, 0)
            SideMenuItemView(label: "common.about",
                             systemImage: "info.circle",
                             context: .toBeImplemnented,
                             showingSideMenu: $showingSideMenu,
                             currentSideMenuContext: $currentSideMenuContext)
                .frame(height: 60)
                .padding(.bottom, 0)
            SideMenuItemView(label: "common.reportproblem",
                             systemImage: "exclamationmark.triangle",
                             context: .toBeImplemnented,
                             showingSideMenu: $showingSideMenu,
                             currentSideMenuContext: $currentSideMenuContext)
                .frame(height: 60)
                .padding(.bottom, 0)

            Spacer()
            
            Rectangle()
                .foregroundStyle(.dropinPrimary)
                .frame(height: 0.5)
            
            Text("developed_by")
                .font(.captionRegular)
                .padding(.top, 20)
                .padding(.bottom, 10)

            Text("_NOTTR_v\(appVersion)(\(appBuild))")
                .font(.caption2Light)
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
                            .foregroundStyle(.backgroundPrimary)
                            .frame(width: 60, height: 60)
                        DropinLogo(variant: logoVariant,
                                   lineWidthMuliplier: 2,
                                   pinSizeMuliplier: 1.5)
                            .frame(width: 50, height: 50)
                    }
                    .padding(.leading, 25)
                    .padding(.trailing, 25)

                    Text("Dropin")
                        .foregroundStyle(.backgroundPrimary)
                        .font(.largeTitleSemibold)

                    Spacer()
                }
                .onTapGesture {
                    logoVariant = DropinLogo.Variant.random(excluded: logoVariant)
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
            showingSideMenu = false
        }
    }
}

#if DEBUG

struct MockSideMenuView: View {
    @State var showingSideMenu: Bool
    @State var sideMenuContext: SideMenuContext
    
    var body: some View {
        SideMenuView(showingSideMenu: $showingSideMenu,
                     currentSideMenuContext: $sideMenuContext)
    }
    
    init() {
        self.showingSideMenu = false
        self.sideMenuContext = .main
    }
}

#Preview {
    MockSideMenuView()
}

#endif
