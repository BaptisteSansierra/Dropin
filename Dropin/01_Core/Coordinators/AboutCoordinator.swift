//
//  AboutCoordinator.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/26.
//

import SwiftUI

@MainActor
@Observable class AboutCoordinator: NavigationCoordinator {

    var path: [AboutNavigationItem] = []

    // MARK: navigation methods
    func pushPrivacyPolicyView() {
        path.append(.privacyPolicy)
    }

    func pushFontAwesomeDetailView() {
        path.append(.fontAwesomeDetail)
    }

    func pop() {
        _ = path.popLast()
    }
}

enum AboutNavigationItem: Hashable {
    case privacyPolicy
    case fontAwesomeDetail
}
