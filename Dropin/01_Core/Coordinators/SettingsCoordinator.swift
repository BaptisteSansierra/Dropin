//
//  SettingsCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/11/26.
//

import SwiftUI

// Currently useless
@MainActor
@Observable class SettingsCoordinator: NavigationCoordinator {

    // MARK: properties
    var path: [SettingsNavigationItem] = []

    // MARK: navigation methods
    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    // MARK: private
    private func push(_ item: SettingsNavigationItem) {
        path.append(item)
    }
}

enum SettingsNavigationItem: Hashable {
    case none
}
