//
//  AuthService.swift
//  Dropin

import Supabase
import Foundation

struct UserSession: Sendable, Equatable {
    let userId: UUID
    let email: String?
}

enum AuthError: Error, Equatable {
    case signInFailed
    case notAuthenticated
}

@MainActor
protocol AuthServiceProtocol: AnyObject, Sendable {
    var session: UserSession? { get }
    var isAuthenticated: Bool { get }
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signInWithApple() async throws   // TODO: implement when Apple Sign-In is added
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
        let user = response.user
        session = UserSession(userId: user.id, email: user.email)
    }

    func signIn(email: String, password: String) async throws {
        let supaSession = try await client.auth.signIn(email: email, password: password)
        session = UserSession(userId: supaSession.user.id, email: supaSession.user.email)
        
        Log.info("Signed in as \(supaSession.user.email ?? "N/A")")
    }

    func signInWithApple() async throws {
        throw AuthError.signInFailed // TODO: Supabase Apple Sign-In
    }

    func signOut() async throws {
        try await client.auth.signOut()
        session = nil
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
