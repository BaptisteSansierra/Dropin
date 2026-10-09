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
    func signUp(email: String, password: String) async throws {}
    func signIn(email: String, password: String) async throws {}
    func signInWithApple() async throws {}
    func resetPassword(email: String) async throws {}
    func resendVerificationEmail(email: String) async throws {}
    func signOut() async throws { session = nil }
    func deleteAccount() async throws { session = nil }
    func restoreSession() async {}
}

#endif
