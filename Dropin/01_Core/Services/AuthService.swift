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
    /// The session is still stored, but refreshing it is rate-limited by Supabase: retry later
    case refreshRateLimited
    case confirmationRequired
    case invalidCredentials
    /// An auth email link already used or expired
    case linkExpired
    /// The new password is the current one
    case samePassword
}

@MainActor
protocol AuthServiceProtocol: AnyObject, Sendable {
    var session: UserSession? { get }
    var isAuthenticated: Bool { get }
    /// Called once when the session is gone for good (revoked, expired refresh token, deleted user…)
    /// without the user signing out. The owner is expected to run the full sign-out cleanup.
    var onSessionLost: (() -> Void)? { get set }

    /// Signed-in user id, guaranteed to be backed by a valid client session (refreshed if needed).
    /// Throws `notAuthenticated` if there's no session, `refreshRateLimited` while refreshing is rate-limited;
    /// network errors are rethrown as is.
    func requireUserId() async throws -> UUID

    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signInWithApple() async throws   // FIXME: DRO-56 > implement when Apple Sign-In is added
    func resetPassword(email: String) async throws
    func resendVerificationEmail(email: String) async throws
    /// Email confirmation link: confirms the email and signs the user in. Throws `linkExpired` for a used/expired link
    func confirmEmail(tokenHash: String) async throws
    /// Password reset link: opens a recovery session, only used to choose a new password (the user isn't signed in).
    /// Returns the account email. Throws `linkExpired` for a used/expired link
    func beginPasswordRecovery(tokenHash: String) async throws -> String
    /// Saves the new password with the recovery session, then signs the user in. Throws `samePassword`
    func completePasswordRecovery(newPassword: String) async throws
    /// Drops the recovery session, the password is unchanged
    func cancelPasswordRecovery() async
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
            refreshBlockedUntil = nil
        }
    }
    var isAuthenticated: Bool { session != nil }
    var onSessionLost: (() -> Void)?
    
    private let client: SupabaseClient
    private let reachability: any ReachabilityServiceProtocol
    
    private var signingIn = false
    private var signingUp = false
    /// Set during `signOut()`: the client session is removed before `session` is cleared,
    /// that window must not be mistaken for a lost session.
    private var signingOut = false
    /// `onSessionLost` is reported once, until the resulting sign-out completes.
    private var sessionLostReported = false
    /// Set when a refresh got rate-limited (429 over_request_rate_limit). Until then, `requireUserId` throws
    /// right away: a failed refresh isn't remembered by supabase-swift, every caller would retry it
    /// (and count against the limit again).
    private var refreshBlockedUntil: Date?
    private let refreshCooldown: TimeInterval = 60
    private var authStateTask: Task<Void, Never>?
    /// Set while a recovery session is open: Supabase stores it like any session, it must not be restored as
    /// a signed-in one if the app is killed before the new password is saved
    private var recoveryPending: Bool {
        get { UserDefaults.standard.bool(forKey: DropinApp.userDefaultsKeys.passwordRecoveryPending) }
        set { UserDefaults.standard.set(newValue, forKey: DropinApp.userDefaultsKeys.passwordRecoveryPending) }
    }
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
            } else if error.errorCode == .invalidCredentials {
                    Log.warning("  > Invalid credentials")
                    throw AuthServiceError.invalidCredentials
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
        try await client.auth.resetPasswordForEmail(email, redirectTo: DropinApp.urls.resetPasswordURL)
        Log.info("Password reset link requested for \(email)")
    }
    
    func resendVerificationEmail(email: String) async throws {
        try await client.auth.resend(email: email, type: .signup)
        Log.info("Verification email resent to \(email)")
    }

    func confirmEmail(tokenHash: String) async throws {
        let response = try await verifyLink(tokenHash: tokenHash, type: .signup)
        guard let s = response.session else {
            Log.warning("Email confirmed without a session")
            throw AuthServiceError.linkExpired
        }
        setSession(UserSession(userId: s.user.id, email: s.user.email))
        Log.info("Email confirmed, signed in")
    }

    func beginPasswordRecovery(tokenHash: String) async throws -> String {
        // Set first: Supabase stores the recovery session as soon as the link is verified
        recoveryPending = true
        do {
            let response = try await verifyLink(tokenHash: tokenHash, type: .recovery)
            guard let email = response.user.email else {
                Log.warning("Recovery link verified for a user without email")
                await cancelPasswordRecovery()
                throw AuthServiceError.linkExpired
            }
            Log.info("Password recovery started")
            return email
        } catch {
            recoveryPending = false
            throw error
        }
    }

    func completePasswordRecovery(newPassword: String) async throws {
        let user: User
        do {
            user = try await client.auth.update(user: UserAttributes(password: newPassword))
        } catch let error as Supabase.AuthError where error.errorCode == .samePassword {
            throw AuthServiceError.samePassword
        } catch AuthError.sessionMissing {
            recoveryPending = false
            throw AuthServiceError.linkExpired
        }
        recoveryPending = false
        setSession(UserSession(userId: user.id, email: user.email))
        Log.info("Password updated, signed in")
    }

    func cancelPasswordRecovery() async {
        recoveryPending = false
        // Removes the stored session first, the server call failing (offline) doesn't matter
        try? await client.auth.signOut(scope: .local)
        Log.info("Password recovery canceled")
    }

    func signOut() async throws {
        signingOut = true
        defer {
            // Success or not (maybe offline), we're clearing session locally
            session = nil
            signingOut = false
            sessionLostReported = false
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
        // The app was killed while choosing a new password: the stored session is a recovery one, not a sign in
        if recoveryPending {
            Log.info("[restoreSession] Dropping an unfinished password recovery")
            await cancelPasswordRecovery()
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
                    // Refresh rejected (revoked session, deleted user…): supabase removed the stored session,
                    // there's nothing left to restore
                    Log.warning("[restoreSession] session could not be refreshed, it is lost")
                    reportSessionLost()
                    return
                case _ where error.errorCode == .overRequestRateLimit:
                    // Not a bug: the session is still stored, keep it like offline and let the cooldown pass
                    Log.warning("[restoreSession] refresh rate-limited, use cached session")
                    session = UserSession(userId: cachedSession.user.id, email: cachedSession.user.email)
                    startRefreshCooldown()
                    return
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
    
    /// supabase-swift silently falls back to the anon key when it has no session
    /// (`SupabaseClient.adapt(request:)` does `try? await auth.session.accessToken`),
    /// so checking `session` alone isn't enough: the client must still have one too.
    /// `client.auth.session` refreshes an expired access token; a network failure there is rethrown
    /// as is (session still stored, the caller retries later).
    func requireUserId() async throws -> UUID {
        guard let session else { throw AuthServiceError.notAuthenticated }
        if let refreshBlockedUntil, refreshBlockedUntil > .now {
            throw AuthServiceError.refreshRateLimited
        }
        do {
            _ = try await client.auth.session
        } catch AuthError.sessionMissing {
            reportSessionLost()
            throw AuthServiceError.notAuthenticated
        } catch let error as AuthError where error.errorCode == .overRequestRateLimit {
            startRefreshCooldown()
            throw AuthServiceError.refreshRateLimited
        }
        return session.userId
    }

    // MARK: - private methods
    /// Verifies an auth email link's token. A used, expired or unknown token throws `linkExpired`
    private func verifyLink(tokenHash: String, type: EmailOTPType) async throws -> AuthResponse {
        do {
            return try await client.auth.verifyOTP(tokenHash: tokenHash, type: type)
        } catch let error as Supabase.AuthError where error.errorCode == .otpExpired {
            Log.warning("Auth link (\(type)) expired or already used")
            throw AuthServiceError.linkExpired
        }
    }

    private func startRefreshCooldown() {
        // Set after `session` in restoreSession: its didSet clears it
        refreshBlockedUntil = .now + refreshCooldown
        Log.warning("Session refresh rate-limited, no remote call for \(Int(refreshCooldown))s")
        DropinTracker.shared.capture("Session refresh rate-limited", authFlow: .refresh_rate_limited)
    }

    private func reportSessionLost() {
        guard !signingOut, !sessionLostReported else { return }
        sessionLostReported = true
        Log.warning("Session lost, signing out")
        DropinTracker.shared.capture("Session lost", authFlow: .session_lost)
        onSessionLost?()
    }

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
                        /*
                         Supabase is configured so the refresh token never expires on its own (a session lasts indefinitely)
                         and multiple sessions per user are allowed, .signedOut would only realistically happen from:
                            - the user actually signing out (handled by signOut(), ignored here)
                            - a password change
                            - account deletion/explicit revoke
                         */
                        guard !self.signingOut else {
                            Log.info(".signedOut received from Supabase while user is effectively signing out, ignore")
                            break
                        }
                        guard self.session != nil else { break }
                        self.reportSessionLost()
                    case .userDeleted:
                        /*
                         .userDeleted seems to never be triggered by supabase
                         Not signing out ourselves: the session is lost, the owner runs the full sign-out cleanup,
                         which clears `session` last
                         */
                        guard self.session != nil else { break }
                        self.reportSessionLost()
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
                let response = try await self.client.auth.signUp(email: email, password: password, redirectTo: DropinApp.urls.emailConfirmedURL)
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
