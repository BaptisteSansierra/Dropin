//
//  RootViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/10/25.
//

import SwiftUI

enum SideMenuContext {
    case main
    case groups
    case tags
    case settings
    case toBeImplemnented
}

@MainActor
@Observable class RootViewModel {

    /// side menu selected section
    //var currentSideMenuContext: SideMenuContext = .main
    //var currentSideMenuContext: Binding<SideMenuContext> //= .main
    var appContext: AppContext

    /// show/hide the side menu
    var showingSideMenu: Bool = false

    /// Source of truth for the Profile flow (its own NavigationStack,
    /// presented modally so it doesn't nest inside this stack-less RootView).
    var showingProfile: Bool = false

    var bindedShowingSideMenu: Binding<Bool> { Binding<Bool> {
        return self.showingSideMenu
    } set: { b in
        self.showingSideMenu = b
    }}

    var bindedShowingProfile: Binding<Bool> { Binding<Bool> {
        return self.showingProfile
    } set: { b in
        self.showingProfile = b
    }}

    var bindedSideMenuContext: Binding<SideMenuContext> { Binding<SideMenuContext> {
        return self.appContext.currentSideMenuContext
    } set: { v in
        self.appContext.currentSideMenuContext = v
    }}

    @ObservationIgnored private var appContainer: AppContainer

    init(_ appContainer: AppContainer,
         appContext: AppContext) {
        self.appContainer = appContainer
        self.appContext = appContext
    }

    func createSideMenuView() -> SideMenuView {
        appContainer.createSideMenuView(showingSideMenu: bindedShowingSideMenu,
                                        currentSideMenuContext: bindedSideMenuContext,
                                        showingProfile: bindedShowingProfile)
    }

    func createProfileView() -> ProfileView {
        appContainer.createProfileView()
    }

    func createPlacesView() -> PlacesView {
        return appContainer.createPlacesView(showingSideMenu: bindedShowingSideMenu)
    }

    func createGroupListView() -> GroupListView {
        return appContainer.createGroupListView(showingSideMenu: bindedShowingSideMenu)
    }

    func createTagListView() -> TagListView {
        return appContainer.createTagListView(showingSideMenu: bindedShowingSideMenu)
    }

    func createSettingsView() -> SettingsView {
        return appContainer.createSettingsView(showingSideMenu: bindedShowingSideMenu)
    }

    func switchAppIcon() {
        let icon = ["AppIcon", "AppIcon2", "AppIcon3", "AppIcon4"][Int.random(in: 0...3)]
        UIApplication.setApplicationIconWithoutAlert(icon)
    }
}
