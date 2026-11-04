//
//  ProfileCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/7/26.
//
//  Owns navigation *within* the Profile flow, presented modally (its own
//  NavigationStack, rooted at ProfileView) from RootView. Not RootView's own
//  stack — SwiftUI doesn't support nesting a NavigationStack inside another
//  one's content without toolbar/nav-bar cross-talk, which is exactly what a
//  shared RootView-level coordinator caused.
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
