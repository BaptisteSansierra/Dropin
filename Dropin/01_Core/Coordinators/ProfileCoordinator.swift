//
//  ProfileCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/7/26.
//

import SwiftUI

@MainActor
@Observable class ProfileCoordinator: NavigationCoordinator {

    // MARK: properties
    var path: [ProfileNavigationItem] = []

    // MARK: navigation methods
    func pushAccountDeletion() {
        push(.accountDeletion)
    }

    func pushEditName() {
        push(.editName)
    }

    private func push(_ item: ProfileNavigationItem) {
        path.append(item)
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}

enum ProfileNavigationItem: Hashable {
    case accountDeletion
    case editName
}
