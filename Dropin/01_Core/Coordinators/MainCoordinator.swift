//
//  MainCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/7/26.
//

import SwiftUI
import CoreLocation

@MainActor
@Observable class MainCoordinator: NavigationCoordinator {
    
    // MARK: properties
    var path: [MainNavigationItem] = []

    // MARK: navigation methods
    func pushProfile() {
        push(.profile)
    }

    func pushAccountDeletion() {
        push(.accountDeletion)
    }

    private func push(_ item: MainNavigationItem) {
        path.append(item)
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}

enum MainNavigationItem: Hashable {
    case profile
    case accountDeletion
    case editName
}
