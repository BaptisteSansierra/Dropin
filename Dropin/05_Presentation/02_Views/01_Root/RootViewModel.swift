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
    var currentSideMenuContext: SideMenuContext = .main
    /// show/hide the side menu
    var showingSideMenu: Bool = false
    
    var bindedShowingSideMenu: Binding<Bool> { Binding<Bool> {
        return self.showingSideMenu
    } set: { b in
        self.showingSideMenu = b
    }}

    

    @ObservationIgnored private var appContainer: AppContainer
    
    init(_ appContainer: AppContainer) {
        self.appContainer = appContainer
    }
    
    func createMainView() -> MainView {
        return appContainer.createMainView(showingSideMenu: bindedShowingSideMenu)
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
