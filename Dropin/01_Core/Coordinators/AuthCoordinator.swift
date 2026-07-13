//
//  AuthCoordinator.swift
//  Dropin
//

import SwiftUI

@MainActor
@Observable class AuthCoordinator: NavigationCoordinator {

    var path: [AuthNavigationItem] = []

    // MARK: navigation methods
    func pushSignUp() {
        path.append(.signUp)
    }

    func pushResetPassword() {
        path.append(.resetPassword)
    }

    func pushVerifyEmail(email: String, password: String) {
        path.append(.verifyEmail(email: email, password: password))
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}

enum AuthNavigationItem: Hashable {
    case signUp
    case resetPassword
    case verifyEmail(email: String, password: String)
}
