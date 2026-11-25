//
//  NewPasswordViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/11/26.
//

import Foundation

/// Reached from a password reset link: a recovery session is open, the user isn't signed in until the new password is saved
@MainActor
@Observable class NewPasswordViewModel {

    let email: String
    var password: String = ""
    var confirmPassword: String = ""
    var isSubmitting: Bool = false
    var lastError: String?

    @ObservationIgnored private var authService: any AuthServiceProtocol
    @ObservationIgnored private var coordinator: AuthCoordinator

    var confirmPasswordError: String? {
        guard !confirmPassword.isEmpty, confirmPassword != password else { return nil }
        return String(localized: "auth.error.password_mismatch")
    }

    var isFormValid: Bool {
        password.isValidPassword() && confirmPassword == password
    }

    init(email: String, authService: any AuthServiceProtocol, coordinator: AuthCoordinator) {
        self.email = email
        self.authService = authService
        self.coordinator = coordinator
    }

    func savePassword() async {
        guard isFormValid, !isSubmitting else { return }
        lastError = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await authService.completePasswordRecovery(newPassword: password)
            // Signed in: the global authStatus flips and DropinApp routes to RootView.
            // The auth flow must start from Sign in after a sign out
            coordinator.popToRoot()
        } catch AuthServiceError.samePassword {
            lastError = String(localized: "auth.new_password.error.same_password")
        } catch AuthServiceError.linkExpired {
            lastError = String(localized: "auth.link.expired.recovery_body")
        } catch {
            Log.error("NewPasswordViewModel: password update failed: \(error)")
            lastError = error.localizedDescription
        }
    }

    // MARK: - Navigation
    /// Back to Sign in: the recovery session is dropped, the password is unchanged
    func cancel() {
        coordinator.pop()
        Task { await authService.cancelPasswordRecovery() }
    }
}
