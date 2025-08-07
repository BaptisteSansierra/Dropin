//
//  AppNavigation.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

@Observable class AppNavigationContext {
    
    enum SideMenuContext {
        case main
        case groups
        case tags
    }
    var currentSideMenuContext: SideMenuContext = .main
    var showingSideMenu: Bool = false
    var pinPlace: SDPlace?
    //var editedPlace: SDPlace?

    var showingCreatePlaceMenu: Bool = false
}
