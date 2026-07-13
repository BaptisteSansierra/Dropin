//
//  SignInViewModel.swift
//  Dropin
//

import Foundation

@MainActor
@Observable class SignInViewModel {

    #if DEBUG
    #if false
    var email: String = "test@dropin.local"
    var password: String = "test12345"
    #else
    var email: String = "baptiste.sansierra@gmail.com"
    var password: String = "Test-12345"
    #endif

    //var email: String = "test@dropin.local"
    //var password: String = "test12345"

    #else
    var email: String = ""      // test@dropin.local
    var password: String = ""   // test12345
    #endif
    var isSubmitting: Bool = false
    var lastError: String?

    var coordinator: AuthCoordinator

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var authService: any AuthServiceProtocol

    var isFormValid: Bool {
        email.isValidEmail() && !password.isEmpty
    }

    init(appContainer: AppContainer, authService: any AuthServiceProtocol, coordinator: AuthCoordinator) {
        self.appContainer = appContainer
        self.authService = authService
        self.coordinator = coordinator
    }

    func signIn() async {
        guard isFormValid else { return }
        lastError = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await authService.signIn(email: email, password: password)
        } catch AuthServiceError.confirmationRequired {
            coordinator.pushVerifyEmail(email: email, password: password)
        } catch {
            Log.error("SignInViewModel: sign-in failed: \(error)")
            lastError = error.localizedDescription
        }
    }

    // MARK: - Navigation
    func pushSignUp() {
        coordinator.pushSignUp()
    }

    func pushResetPassword() {
        coordinator.pushResetPassword()
    }

    // MARK: - UI Child
    func createSignUpView() -> SignUpView {
        appContainer.createSignUpView()
    }

    func createResetPasswordView() -> ResetPasswordView {
        appContainer.createResetPasswordView()
    }

    func createVerifyEmailView(email: String, password: String) -> VerifyEmailView {
        appContainer.createVerifyEmailView(email: email, password: password)
    }
}
