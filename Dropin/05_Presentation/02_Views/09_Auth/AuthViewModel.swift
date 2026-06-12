//
//  AuthViewModel.swift
//  Dropin
//

import Foundation

@MainActor
@Observable class AuthViewModel {

    var isSigningIn: Bool = false
    var lastError: String?

    @ObservationIgnored private var authService: any AuthServiceProtocol

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    /// TEMP — signs in the dev user. Replace once a real email/password form ships.
    func signInDevUser() async {
        lastError = nil
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            try await authService.signIn(email: "test@dropin.local",
                                         password: "test12345")
            Log.info("AuthViewModel: signed in as dev user")
        } catch {
            Log.error("AuthViewModel: dev sign-in failed: \(error)")
            lastError = error.localizedDescription
        }
    }
}
