//
//  SideMenuView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

struct SideMenuView: View {

    // MARK: - States & Bindings
    @State private var viewModel: SideMenuViewModel
    @Binding private var showingSideMenu: Bool
    @Binding private var currentSideMenuContext: SideMenuContext
    @State private var logoVariant: DropinLogo.Variant = .logo

    // MARK: - private properties
    private var appVersion: String = ""
    private var appBuild: String = ""
    private var edgeTransition: AnyTransition = .move(edge: .leading)

    // MARK: - init
    init(viewModel: SideMenuViewModel,
         showingSideMenu: Binding<Bool>,
         currentSideMenuContext: Binding<SideMenuContext>) {
        self.viewModel = viewModel
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
        .ignoresSafeArea(edges: .top)
        .animation(.easeInOut, value: showingSideMenu)
    }
    
    // MARK: - Subviews
    var content: some View {
        VStack(spacing: 0) {
            headerView
           
            sectionsView
            
            Spacer()
            
            footerView
        }
    }
        
    private var headerView: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.dropinPrimary)
            VStack {
                Spacer()
                    .frame(height: 70)
                HStack(alignment: .center, spacing: 16) {
                                        
                    ProfileBadgeView(initials: viewModel.avatarInitial,
                                     style: .small,
                                     bgColor: .dropinPrimary,
                                     fgColor: .backgroundPrimary,
                                     stroke: .white)

                    .padding(.leading, 25)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: viewModel.headerTitle)
                            .foregroundStyle(.backgroundPrimary)
                            .font(.sidebarTitle)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(verbatim: viewModel.headerSubtitle)
                            .foregroundStyle(.backgroundPrimary.opacity(0.75))
                            .font(.sidebarSubtitle)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.openProfile()
                }

                Spacer()
            }
        }
        .frame(height: 160)
    }
    
    private var sectionsView: some View {
        VStack(spacing: 0) {
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
                             context: .settings,
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
        }
    }
    
    private var footerView: some View {
        //ZStack {
//            HStack {
//                DropinLogo(variant: logoVariant,
//                           lineWidthMuliplier: 1.5,
//                           pinSizeMuliplier: 1.5)
//                    .frame(width: 25, height: 25)
//                    .padding(.leading, 30)
//                Spacer()
//            }
//            .contentShape(Rectangle())
//            .onTapGesture {
//                logoVariant = DropinLogo.Variant.random(excluded: logoVariant)
//            }
            
            VStack(spacing: 0) {
                Rectangle()
                    .foregroundStyle(.dropinPrimary)
                    .frame(height: 0.5)
                
                DropinLogo(variant: logoVariant,
                           lineWidthMuliplier: 1.5,
                           pinSizeMuliplier: 1.5)
                    .frame(width: 25, height: 25)
                    .padding(.top, 10)
                    .padding(.bottom, 0)
                    .onTapGesture {
                        logoVariant = DropinLogo.Variant.random(excluded: logoVariant)
                    }
                
                Text("developed_by \(DropinApp.strings.developer)")
                    .font(.captionRegular)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                
                Text(verbatim: "v\(appVersion)(\(appBuild))")
                    .font(.caption2Light)
                    .padding(.bottom, 20)
            }
        //}
    }


    // Legacy logo header — kept for reference; the profile-aware version above
    // replaces it. Delete once we're sure we're not reverting.
    /*
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

                    Text(verbatim: DropinApp.strings.app)
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
    */
    
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
    @State var showingProfileSheet: Bool = false
    var mock: MockContainer

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Button {
                    self.showingSideMenu.toggle()
                } label: {
                    Text("TOGGLE")
                }
                Spacer()
            }
            mock.appContainer.createSideMenuView(showingSideMenu: $showingSideMenu,
                                                 currentSideMenuContext: $sideMenuContext,
                                                 showingProfileSheet: $showingProfileSheet)
        }
        .task {
            // Load john does' profile
            self.mock.loadProfile()

            // Show menu
            self.showingSideMenu = true
        }
        .sheet(isPresented: $showingProfileSheet) {
            Text("User profile")
        }
    }

    init() {
        self.showingSideMenu = false
        self.sideMenuContext = .main
        self.mock = MockContainer()
    }
}

#Preview {
    MockSideMenuView()
}

#endif
