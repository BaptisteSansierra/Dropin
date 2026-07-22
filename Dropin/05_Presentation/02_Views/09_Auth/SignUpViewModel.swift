//
//  SignUpViewModel.swift
//  Dropin
//

import Foundation

@MainActor
@Observable class SignUpViewModel {

    var displayName: String = ""
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var isSubmitting: Bool = false
    var lastError: String?

    @ObservationIgnored private var authService: any AuthServiceProtocol
    @ObservationIgnored private var coordinator: AuthCoordinator

    var emailError: String? {
        guard !email.isEmpty, !email.isValidEmail() else { return nil }
        return String(localized: "auth.error.invalid_email")
    }

    var confirmPasswordError: String? {
        guard !confirmPassword.isEmpty, confirmPassword != password else { return nil }
        return String(localized: "auth.error.password_mismatch")
    }

    var isFormValid: Bool {
        email.isValidEmail()
            && password.isValidPassword()
            && confirmPassword == password
    }

    init(authService: any AuthServiceProtocol, coordinator: AuthCoordinator) {
        self.authService = authService
        self.coordinator = coordinator
        #if DEBUG
        displayName = "batobat"
        email = "baptiste.sansierra@gmail.com"
        password = "Test-12345"
        confirmPassword = "Test-12345"
        #endif
    }

    func signUp() async {
        guard isFormValid else { return }
        lastError = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await authService.signUp(email: email, password: password)
            // No confirmationRequired thrown — Supabase returned a session
            // directly; the global authStatus flips and DropinApp routes to
            // RootView on its own, nothing to do here.
        } catch AuthServiceError.confirmationRequired {
            coordinator.pushVerifyEmail(email: email, password: password, context: .justSignedUp)
        } catch {
            Log.error("SignUpViewModel: sign-up failed: \(error)")
            lastError = error.localizedDescription
        }
    }

    // MARK: - Navigation
    func pop() {
        coordinator.pop()
    }
}
