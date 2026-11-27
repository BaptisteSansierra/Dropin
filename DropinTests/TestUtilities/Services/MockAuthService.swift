//
//  MockAuthService.swift
//  DropinTests
//
//  Created by baptiste sansierra on 25/11/26.
//

import Foundation
@testable import Dropin

/// Records the Apple sign-in and account deletion calls, throws `appleError` / `deleteError` when set
@MainActor
final class MockAuthService: AuthServiceProtocol {

    var session: UserSession? = nil
    var isAuthenticated: Bool { session != nil }
    var hasAppleIdentity = false
    var onSessionLost: (() -> Void)?

    var appleError: Error?
    private(set) var appleCalls: [(idToken: String, nonce: String)] = []
    /// Called by `signInWithApple`, before it succeeds or throws
    var onSignInWithApple: (() -> Void)?

    var deleteError: Error?
    private(set) var deleteCalls: [String?] = []

    func requireUserId() async throws -> UUID {
        guard let session else { throw AuthServiceError.notAuthenticated }
        return session.userId
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        appleCalls.append((idToken, nonce))
        onSignInWithApple?()
        if let appleError { throw appleError }
        session = UserSession(userId: UUID(), email: "john.doe@example.com")
    }

    func signUp(email: String, password: String) async throws {}
    func signIn(email: String, password: String) async throws {}
    func resetPassword(email: String) async throws {}
    func resendVerificationEmail(email: String) async throws {}
    func confirmEmail(tokenHash: String) async throws {}
    func beginPasswordRecovery(tokenHash: String) async throws -> String { "" }
    func completePasswordRecovery(newPassword: String) async throws {}
    func cancelPasswordRecovery() async {}
    func signOut() async throws { session = nil }
    func deleteAccount(appleAuthorizationCode: String?) async throws {
        deleteCalls.append(appleAuthorizationCode)
        if let deleteError { throw deleteError }
        session = nil
    }
    func restoreSession() async {}
}
