//
//  NavigationContext.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

/// NavigationContext owns the navigation context values as :
///  - current sidebar section
///  - showing stuff(dialog, sheet, ...) state boolean
///  - ...
@MainActor
@Observable class NavigationContext {
    
//    enum SideMenuContext {
//        case main
//        case groups
//        case tags
//    }
//    /// side menu selected section
//    var currentSideMenuContext: SideMenuContext = .main
    /// show/hide the side menu
    var showingSideMenu: Bool = false
    /// show/hide the 'create new place' menu
    var showingCreatePlaceMenu: Bool = false

    
//    /// `pinPlace` is defined when a place annotation is selected on the map
//    /// toggle the corresponding sheet
//    var pinPlace: SDPlace?
//
    /// show/hide the copied to clipboard alert
    var showingAddressToClipboard: Bool = false
//    
    var navigationPath = NavigationPath()

    
    //var searchBarPresented: Bool = false

}
