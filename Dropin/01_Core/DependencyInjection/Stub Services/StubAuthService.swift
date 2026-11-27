//
//  StubAuthService.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/10/26.
//

//  No-op auth services used by MockContainer (previews + tests)
//  so the app target can be built without real Supabase credentials.
#if DEBUG

import Foundation

@MainActor
final class StubAuthService: AuthServiceProtocol {
    
    var session: UserSession? = nil
    var isAuthenticated: Bool { session != nil }
    var hasAppleIdentity: Bool = false
    var onSessionLost: (() -> Void)?
    private let restoredSession: UserSession?

    /// `restoredSession`: session set by `restoreSession()` (signed-in launch), nil → sign-in flow
    init(restoredSession: UserSession? = nil) {
        self.restoredSession = restoredSession
    }

    func requireUserId() async throws -> UUID {
        guard let session else { throw AuthServiceError.notAuthenticated }
        return session.userId
    }

    func signUp(email: String, password: String) async throws {}
    func signIn(email: String, password: String) async throws {}
    func signInWithApple(idToken: String, nonce: String) async throws {}
    func resetPassword(email: String) async throws {}
    func resendVerificationEmail(email: String) async throws {}
    func confirmEmail(tokenHash: String) async throws {}
    func beginPasswordRecovery(tokenHash: String) async throws -> String { "alex@example.com" }
    func completePasswordRecovery(newPassword: String) async throws {}
    func cancelPasswordRecovery() async {}
    func signOut() async throws { session = nil }
    func deleteAccount(appleAuthorizationCode: String?) async throws { session = nil }
    func restoreSession() async { session = restoredSession }
}

#endif
