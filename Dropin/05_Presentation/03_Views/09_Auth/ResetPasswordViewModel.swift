//
//  ResetPasswordViewModel.swift
//  Dropin
//

import Foundation

@MainActor
@Observable class ResetPasswordViewModel {

    var email: String = ""
    var isSubmitting: Bool = false
    var lastError: String?
    var isSent: Bool = false

    @ObservationIgnored private var authService: any AuthServiceProtocol
    @ObservationIgnored private var coordinator: AuthCoordinator

    var isFormValid: Bool {
        email.isValidEmail()
    }

    init(authService: any AuthServiceProtocol, coordinator: AuthCoordinator) {
        self.authService = authService
        self.coordinator = coordinator
    }

    func sendResetLink() async {
        guard isFormValid else { return }
        lastError = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await authService.resetPassword(email: email)
            isSent = true
        } catch {
            Log.error("ResetPasswordViewModel: reset request failed: \(error)")
            lastError = error.localizedDescription
        }
    }

    // MARK: - Navigation
    func pop() {
        coordinator.pop()
    }
}
