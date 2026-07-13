//
//  AuthService.swift
//  Dropin

import Supabase
import Foundation

private struct SignOutTimeout: Error {}

struct UserSession: Sendable, Equatable {
    let userId: UUID
    let email: String?
}

enum AuthServiceError: Error, Equatable {
    case signInFailed
    case notAuthenticated
    /// Sign-up succeeded but the Supabase project requires email confirmation,
    /// so no session was returned — the user isn't authenticated yet.
    case confirmationRequired
}

@MainActor
protocol AuthServiceProtocol: AnyObject, Sendable {
    var session: UserSession? { get }
    var isAuthenticated: Bool { get }
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signInWithApple() async throws   // TODO: implement when Apple Sign-In is added
    func resetPassword(email: String) async throws
    func resendVerificationEmail(email: String) async throws
    func signOut() async throws
    func restoreSession() async
}

@Observable
@MainActor
final class AuthService: AuthServiceProtocol {
    private(set) var session: UserSession? = nil
    var isAuthenticated: Bool { session != nil }

    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)
        // When the Supabase project requires email confirmation, `session` is
        // nil (only `user` is returned) — don't mark the user as
        // authenticated until they've confirmed and actually signed in.
        guard let supaSession = response.session else {
            Log.info("Signed up as \(response.user.email ?? "N/A"), awaiting email confirmation")
            throw AuthServiceError.confirmationRequired
        }
        session = UserSession(userId: supaSession.user.id, email: supaSession.user.email)
        Log.info("Signed up as \(supaSession.user.email ?? "N/A")")
    }

    func signIn(email: String, password: String) async throws {
        do {
            let supaSession = try await client.auth.signIn(email: email, password: password)
            session = UserSession(userId: supaSession.user.id, email: supaSession.user.email)
            Log.info("Signed in as \(supaSession.user.email ?? "N/A")")
        } catch let error as Supabase.AuthError {
            if error.errorCode == .emailNotConfirmed {
                throw AuthServiceError.confirmationRequired
            } else {
                throw error
            }
        }
    }

    func signInWithApple() async throws {
        throw AuthServiceError.signInFailed // TODO: Supabase Apple Sign-In
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
        Log.info("Password reset link requested for \(email)")
    }

    func resendVerificationEmail(email: String) async throws {
        try await client.auth.resend(email: email, type: .signup)
        Log.info("Verification email resent to \(email)")
    }

    func signOut() async throws {
        defer {
            // Success or not (maybe offline), we're clearing session locally
            session = nil
        }
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await self.client.auth.signOut()
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(3))
                    throw SignOutTimeout()
                }
                try await group.next() // first complete win
                group.cancelAll()
            }
            Log.info("Remote signOut completed")
        } catch is SignOutTimeout {
            Log.warning("signOut is took more than 3 seconds, ignore it, wipe session")
        } catch {
            Log.warning("signOut failed (\(error)), wipe session anyway")
        }
    }

    func restoreSession() async {
        do {
            let supaSession = try await client.auth.session
            session = UserSession(userId: supaSession.user.id, email: supaSession.user.email)
            Log.info("Restored session as \(supaSession.user.email ?? "N/A")")
        } catch {
            session = nil
        }
    }
}
