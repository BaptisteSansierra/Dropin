//
//  VerifyEmailViewModel.swift
//  Dropin
//

import Foundation

@MainActor
@Observable class VerifyEmailViewModel {

    static let resendCooldown = 60

    let email: String
    private let password: String
    var isResending: Bool = false
    var isCheckingConfirmation: Bool = false
    var lastError: String?
    var remainingSeconds: Int = VerifyEmailViewModel.resendCooldown

    @ObservationIgnored private var authService: any AuthServiceProtocol
    @ObservationIgnored private var coordinator: AuthCoordinator
    @ObservationIgnored private var countdownTask: Task<Void, Never>?

    var canResend: Bool { remainingSeconds <= 0 }

    var formattedCountdown: String {
        String(format: "%01d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    init(email: String, password: String, authService: any AuthServiceProtocol, coordinator: AuthCoordinator) {
        self.email = email
        self.password = password
        self.authService = authService
        self.coordinator = coordinator
        startCountdown()
    }

    deinit {
        countdownTask?.cancel()
    }

    func resend() async {
        guard canResend else { return }
        lastError = nil
        isResending = true
        defer { isResending = false }
        do {
            try await authService.resendVerificationEmail(email: email)
            remainingSeconds = Self.resendCooldown
            startCountdown()
        } catch {
            Log.error("VerifyEmailViewModel: resend failed: \(error)")
            lastError = error.localizedDescription
        }
    }

    /// Only reliable way to check confirmation without a service-role key:
    /// attempt the sign-in the user will eventually need to do anyway. Success
    /// sets the session and the global authStatus flip routes away, same as
    /// any other sign-in — nothing else to do here. Failure here is almost
    /// certainly "email not confirmed yet" rather than a wrong password,
    /// since the password was typed moments ago on the sign-up screen.
    func checkConfirmationAndSignIn() async {
        lastError = nil
        isCheckingConfirmation = true
        defer { isCheckingConfirmation = false }
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            Log.error("VerifyEmailViewModel: confirmation check failed: \(error)")
            lastError = String(localized: "auth.verify.not_confirmed_yet")
        }
    }

    // MARK: - Navigation
    func changeEmailAddress() {
        coordinator.pop()
    }

    // MARK: - private
    private func startCountdown() {
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            while let self, self.remainingSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.remainingSeconds -= 1
            }
        }
    }
}
