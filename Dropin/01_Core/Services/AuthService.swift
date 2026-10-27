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
    case signInTimedOut
    case signUpTimedOut
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
    func deleteAccount() async throws
    func restoreSession() async
}

@Observable
@MainActor
final class AuthService: AuthServiceProtocol {
    private(set) var session: UserSession? = nil {
        didSet {
            updateTrackedUser()
        }
    }
    var isAuthenticated: Bool { session != nil }
    
    private let client: SupabaseClient
    private let reachability: any ReachabilityServiceProtocol
    
    private var signingIn = false
    private var signingUp = false
    private var authStateTask: Task<Void, Never>?
    private var signInTimeoutInterval = 15
    private var signUpTimeoutInterval = 15
    private var signOutTimeoutInterval = 3
    
    init(client: SupabaseClient,
         reachability: any ReachabilityServiceProtocol) {
        self.client = client
        self.reachability = reachability
        observeAuthStateChanges()
    }
    
    func signUp(email: String, password: String) async throws {
        guard !signingUp else { return }
        signingUp = true
        defer { signingUp = false }
        
        Log.info("Signing up...")
        do {
            try await withThrowingTaskGroup(of: Void.self) { ttg in
                ttg.addTask {
                    let response = try await self.client.auth.signUp(email: email, password: password, redirectTo: DropinApp.strings.emailConfirmedURL)
                    // When the Supabase project requires email confirmation, `session` is nil (only `user` is returned)
                    // don't mark the user as authenticated until they've confirmed and actually signed in.
                    guard let supaSession = response.session else {
                        Log.info("  > Signed up as \(response.user.email ?? "N/A"), awaiting email confirmation")
                        throw AuthServiceError.confirmationRequired
                    }
                    await self.setSession(UserSession(userId: supaSession.user.id, email: supaSession.user.email))
                    Log.info("  > Signed up as \(supaSession.user.email ?? "N/A")")
                }
                ttg.addTask {
                    try await Task.sleep(for: .seconds(self.signUpTimeoutInterval))
                    Log.info("  > Signup timeout triggered")
                    throw AuthServiceError.signUpTimedOut
                }
                try await ttg.next() // first complete win
                ttg.cancelAll()
            }
            Log.info("  > Signup completed")
        } catch let error as AuthServiceError {
            // No-op : Just forward the error we just throw
            throw error
        } catch let error as Supabase.AuthError {
            DropinTracker.shared.capture("Unexpected Supabase error(\(error.errorCode)) \(error)", authFlow: .signup)
            Log.warning("  > Unexpected supabase error \(error)")
            assertionFailure()
            throw error
        } catch {
            DropinTracker.shared.capture("Unexpected error \(error)", authFlow: .signup)
            Log.warning("  > Signin failed (\(error)), wipe session anyway")
            assertionFailure()
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        guard !signingIn else { return }
        signingIn = true
        defer { signingIn = false }
        
        Log.info("Signin in...")
        do {
            try await withThrowingTaskGroup(of: Void.self) { ttg in
                ttg.addTask {
                    let supaSession = try await self.client.auth.signIn(email: email, password: password)
                    await self.setSession(UserSession(userId: supaSession.user.id, email: supaSession.user.email))
                    Log.info("  > Signed in as \(supaSession.user.email ?? "N/A")")
                }
                ttg.addTask {
                    try await Task.sleep(for: .seconds(self.signInTimeoutInterval))
                    Log.warning("  > Signin timeout triggered")
                    throw AuthServiceError.signInTimedOut
                }
                try await ttg.next() // first complete win
                ttg.cancelAll()
            }
            Log.info("  > Signin completed")
        } catch let error as AuthServiceError {
            // No-op : Just forward the error we just throw
            throw error
        } catch let error as Supabase.AuthError {
            if error.errorCode == .emailNotConfirmed {
                Log.warning("  > Email not confirmed")
                throw AuthServiceError.confirmationRequired
            } else {
                DropinTracker.shared.capture("Unexpected Supabase error(\(error.errorCode)) \(error)", authFlow: .signin)
                Log.warning("  > Unexpected supabase error \(error)")
                assertionFailure()
                throw error
            }
        } catch {
            DropinTracker.shared.capture("Unexpected error \(error)", authFlow: .signin)
            Log.warning("  > Signin failed (\(error)), wipe session anyway")
            assertionFailure()
            throw error
        }
    }
    
    func signInWithApple() async throws {
        throw AuthServiceError.signInFailed // TODO: Supabase Apple Sign-In
    }
    
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email, redirectTo: DropinApp.strings.resetPasswordURL)
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
            try await withThrowingTaskGroup(of: Void.self) { category in
                category.addTask {
                    try await self.client.auth.signOut()
                }
                category.addTask {
                    try await Task.sleep(for: .seconds(self.signOutTimeoutInterval))
                    throw SignOutTimeout()
                }
                try await category.next() // first complete win
                category.cancelAll()
            }
            Log.info("Remote signOut completed")
        } catch is SignOutTimeout {
            Log.warning("SignOut is took more than 3 seconds, ignore it, wipe session")
        } catch {
            Log.warning("SignOut failed (\(error)), wipe session anyway")
        }
    }
    
    /// Deletes the current user's account. Server-side, this removes their storage objects and deletes the auth user;
    /// app tables cascade from there (see Dropin_backend's delete-account edge function).
    /// Does not touch local session/data, the caller clears those on success.
    func deleteAccount() async throws {
        try await client.functions.invoke("delete-account")
        Log.info("Account deleted")
    }
    
    func restoreSession() async {
        guard session == nil else {
            assertionFailure("restoreSession called while session is already defined")
            return
        }
        // Check Supabase has a sessions to restore
        guard let cachedSession = client.auth.currentSession else {
            Log.info("[restoreSession] No previous session to restore")
            return
        }
        // Do not even try without reachability
        guard reachability.isConnected else {
            Log.info("[restoreSession] Not connected, use cached session")
            session = UserSession(userId: cachedSession.user.id, email: cachedSession.user.email)
            return
        }
        // Refresh session if needed
        do {
            let supaSession = try await client.auth.session
            session = UserSession(userId: supaSession.user.id, email: supaSession.user.email)
            Log.info("[restoreSession] Restored session as \(supaSession.user.email ?? "'undefined email'")")
        } catch let error as Supabase.AuthError {
            switch error {
                case .sessionMissing:
                    // We found a currentSession but session call says otherwise ?...
                    Log.error("[restoreSession] currentSession defined but session says 'sessionMissing'")
                default:
                    Log.error("[restoreSession] Supabase error(\(error.errorCode)): \(error)")
            }
            
            DropinTracker.shared.capture("Unexpected supabase error\(error.errorCode) \(error)", authFlow: .restore_session)
            assertionFailure()

            // Try it anyway
            session = UserSession(userId: cachedSession.user.id, email: cachedSession.user.email)
        } catch {
            if let eu = error as? URLError {
                switch eu.code {
                    case .notConnectedToInternet, .timedOut, .networkConnectionLost, .cannotConnectToHost:
                        Log.debug("[restoreSession] offline-ish failure: \(error)")
                    default:
                        DropinTracker.shared.capture("Unexpected URLError error\(eu.errorCode) \(eu)", authFlow: .restore_session)
                        Log.debug("[restoreSession] undefined URLError: \(error)")
                        assertionFailure()
                }
            } else {
                DropinTracker.shared.capture("Unexpected error \(error)", authFlow: .restore_session)
                Log.debug("[restoreSession] undefined error: \(error)")
                assertionFailure()
            }
            // Try it anyway
            session = UserSession(userId: cachedSession.user.id, email: cachedSession.user.email)
        }
    }
    
    // MARK: - private methods
    private func updateTrackedUser() {
        guard let session = session else {
            DropinTracker.shared.resetUser()
            return
        }
        DropinTracker.shared.setUser(id: session.userId.uuidString,
                                     email: session.email)
    }
    
    @MainActor private func setSession(_ session: UserSession?) {
        self.session = session
    }
    
    /// Observe authStateChanges stream in order to update session when needed
    private func observeAuthStateChanges() {
        authStateTask = Task { [weak self] in
            guard let self else { return }
            for await (event, supaSession) in self.client.auth.authStateChanges {
                switch event {
                    case .tokenRefreshed, .signedIn, .userUpdated:
                        if let supaSession {
                            self.setSession(UserSession(userId: supaSession.user.id, email: supaSession.user.email))
                            Log.info("Auth state changed (\(event)): \(supaSession.user.email ?? "N/A")")
                        }
                    case .signedOut:
                        // FIXME: DRO-54 :
                        /*
   Supabase is configured so the refresh token never expires on its own (a session lasts indefinitely) and multiple sessions per user are allowed
   .signedOut would only realistically happen from:
     - the user actually signing out
     - a password change
     - account deletion/explicit revoke
                         */
                        self.setSession(nil)
                    case .userDeleted:
                        // It seems this case is never triggered by supabase
                        // anyway FIXME: DRO-54
                        self.setSession(nil)
                    case .initialSession, .passwordRecovery, .mfaChallengeVerified:
                        break
                    @unknown default:
                        break
                }
            }
        }
    }
}
