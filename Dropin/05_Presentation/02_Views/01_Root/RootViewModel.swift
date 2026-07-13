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

    var coordinator: MainCoordinator

    /// show/hide the side menu
    var showingSideMenu: Bool = false

    /// Source of truth for the profile sheet. RootView attaches the actual
    /// `.sheet(isPresented:)`; SideMenuView receives a Binding to flip it.
    var showingProfileSheet: Bool = false

    var bindedShowingSideMenu: Binding<Bool> { Binding<Bool> {
        return self.showingSideMenu
    } set: { b in
        self.showingSideMenu = b
    }}

    var bindedShowingProfileSheet: Binding<Bool> { Binding<Bool> {
        return self.showingProfileSheet
    } set: { b in
        self.showingProfileSheet = b
    }}

    var bindedSideMenuContext: Binding<SideMenuContext> { Binding<SideMenuContext> {
        return self.appContext.currentSideMenuContext
    } set: { v in
        self.appContext.currentSideMenuContext = v
    }}

    @ObservationIgnored private var appContainer: AppContainer

    init(_ appContainer: AppContainer,
         appContext: AppContext,
         coordinator: MainCoordinator) {
        self.appContainer = appContainer
        self.appContext = appContext
        self.coordinator = coordinator
    }

    func createSideMenuView() -> SideMenuView {
        appContainer.createSideMenuView(showingSideMenu: bindedShowingSideMenu,
                                        currentSideMenuContext: bindedSideMenuContext,
                                        showingProfileSheet: bindedShowingProfileSheet)
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
