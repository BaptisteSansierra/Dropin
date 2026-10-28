//
//  AuthService.swift
//  Dropin

import Supabase
import Foundation

struct UserSession: Sendable, Equatable {
    let userId: UUID
    let email: String?
}

enum AuthServiceError: Error, Equatable {
    case signInFailed
    case signInTimedOut
    case signUpTimedOut
    case signOutTimedOut
    case notAuthenticated
    case confirmationRequired
}

@MainActor
protocol AuthServiceProtocol: AnyObject, Sendable {
    var session: UserSession? { get }
    var isAuthenticated: Bool { get }

    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signInWithApple() async throws   // FIXME: DRO-56 > implement when Apple Sign-In is added
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
            let s = try await signupWithTimeout(email: email, password: password)
            setSession(UserSession(userId: s.user.id, email: s.user.email))
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
            let s = try await signinWithTimeout(email: email, password: password)
            setSession(UserSession(userId: s.user.id, email: s.user.email))
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
        throw AuthServiceError.signInFailed // FIXME: DRO-56 > Supabase Apple Sign-In
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
            try await signoutWithTimeout()
            Log.info("Remote signOut completed")
        } catch is AuthServiceError {
            Log.warning("SignOut took more than 3 seconds, ignore it, wipe session")
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
            let s: Session = try await refreshedSessionWithTimeout()
            setSession(UserSession(userId: s.user.id, email: s.user.email))
        } catch is AuthServiceError {
            Log.debug("  -> CREATE SESSION FROM CACHE")
            session = UserSession(userId: cachedSession.user.id, email: cachedSession.user.email)
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
            if error.isOffline || error.isTimeout {
                Log.debug("[restoreSession] offline-ish failure: \(error)")
            } else if let eu = error as? URLError {
                DropinTracker.shared.capture("Unexpected URLError error\(eu.errorCode) \(eu)", authFlow: .restore_session)
                Log.debug("[restoreSession] undefined URLError: \(error)")
                assertionFailure()
            } else {
                DropinTracker.shared.capture("Unexpected error \(error)", authFlow: .restore_session)
                Log.debug("[restoreSession] unexpected error: \(error)")
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
                    case .tokenRefreshed, .signedIn:
                         // No-op
                        ()
                    case .userUpdated:
                        guard let supaSession else { return }
                        // Extermely rare case where the user updated the email in another device...
                        self.setSession(UserSession(userId: supaSession.user.id, email: supaSession.user.email))
                        Log.info("Auth state changed (\(event)): \(supaSession.user.email ?? "N/A")")
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
    
    private func signupWithTimeout(email: String, password: String) async throws -> Session {
        let (stream, continuation) = AsyncThrowingStream<Session, Error>.makeStream()
        let work = Task {
            do {
                let response = try await self.client.auth.signUp(email: email, password: password, redirectTo: DropinApp.strings.emailConfirmedURL)
                // When the Supabase project requires email confirmation, `session` is nil (only `user` is returned)
                // don't mark the user as authenticated until they've confirmed and actually signed in.
                guard let supaSession = response.session else {
                    Log.info("  > Signed up as \(response.user.email ?? "N/A"), awaiting email confirmation")
                    continuation.finish(throwing: AuthServiceError.confirmationRequired)
                    return
                }
                Log.info("  > Signed up as \(supaSession.user.email ?? "N/A")")
                continuation.yield(supaSession)
                continuation.finish()
            }
            catch { continuation.finish(throwing: error) }
        }
        let timeout = Task {
            try await Task.sleep(for: .seconds(signUpTimeoutInterval))
            Log.info("  > Signup timeout triggered")
            continuation.finish(throwing: AuthServiceError.signUpTimedOut)
        }
        defer { work.cancel(); timeout.cancel() }
        for try await value in stream { return value }
        throw CancellationError()
    }
    
    private func signinWithTimeout(email: String, password: String) async throws -> Session {
        let (stream, continuation) = AsyncThrowingStream<Session, Error>.makeStream()
        let work = Task {
            do {
                let supaSession = try await self.client.auth.signIn(email: email, password: password)
                Log.info("  > Signed in as \(supaSession.user.email ?? "N/A")")
                continuation.yield(supaSession)
                continuation.finish()
            }
            catch { continuation.finish(throwing: error) }
        }
        let timeout = Task {
            try await Task.sleep(for: .seconds(signInTimeoutInterval))
            Log.info("  > Signin timeout triggered")
            continuation.finish(throwing: AuthServiceError.signInTimedOut)
        }
        defer { work.cancel(); timeout.cancel() }
        for try await value in stream { return value }
        throw CancellationError()
    }
    
    private func signoutWithTimeout() async throws {
        let (stream, continuation) = AsyncThrowingStream<Void, Error>.makeStream()
        let work = Task {
            do {
                try await self.client.auth.signOut()
                continuation.yield()   // give an empty value to the stream so it will return before CancellationError
                continuation.finish()
            }
            catch { continuation.finish(throwing: error) }
        }
        let timeout = Task {
            try await Task.sleep(for: .seconds(self.signOutTimeoutInterval))
            continuation.finish(throwing: AuthServiceError.signOutTimedOut)
        }
        defer { work.cancel(); timeout.cancel() }
        for try await value in stream { return value }
        throw CancellationError()
    }

    private func refreshedSessionWithTimeout() async throws -> Session {
        let (stream, continuation) = AsyncThrowingStream<Session, Error>.makeStream()
        let work = Task {
            do {
                let s = try await self.client.auth.session
                continuation.yield(s)
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        let timeout = Task {
            try await Task.sleep(for: .seconds(self.signInTimeoutInterval))
            continuation.finish(throwing: AuthServiceError.signInTimedOut)
        }
        defer {
            work.cancel()
            timeout.cancel()
        }
        // returns right away on first value or error
        for try await value in stream { return value }
        try Task.checkCancellation() // Can only be reached if parent Task was canceled, which won't happen
        throw CancellationError()    // unreachable in practice, but keeps the compiler happy
    }
}
