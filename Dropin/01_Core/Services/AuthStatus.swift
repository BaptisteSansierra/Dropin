//
//  AuthStatus.swift
//  Dropin
//
//  Observable wrapper exposing a tri-state derived from AuthService.session and
//  an in-flight `restoreSession()` flag. Drives the root-level routing in
//  DropinApp: splash while restoring → SignInView (auth flow) if no session →
//  RootView if signed in.
//

import Foundation

@MainActor
@Observable
final class AuthStatus {

    enum State {
        case loading
        case signedIn(signingOut: Bool)
        case signedOut
    }

    /// True while initial `restoreSession()` is in flight. Flipped to false by
    /// the call site (`AppContainer.restoreSession()`) once the restore returns.
    var isRestoring: Bool = true

    /// True while `signout()` is in flight. Flipped to false when done
    var isSigningOut: Bool = false

    @ObservationIgnored private let authService: any AuthServiceProtocol

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    /// Derived: the access to both `isRestoring` and `authService.session`
    /// registers observation, so consumers re-render on either change.
    var state: State {
        if isRestoring {
            Log.debug("AuthStatus is loading")
            return .loading
        }
        let s: State = authService.session != nil ? .signedIn(signingOut: isSigningOut) : .signedOut
        Log.debug("AuthStatus is \(s)")
        return s
    }
}
