//
//  SignInViewModel.swift
//  Dropin
//

import Foundation

@MainActor
@Observable class SignInViewModel {

    #if DEBUG
    var email: String = AppConfig.DebugCredentials.email          // Config.xcconfig: DEBUG_SIGNIN_ACCOUNT
    var password: String = AppConfig.DebugCredentials.password
    #else
    var email: String = ""
    var password: String = ""
    #endif
    var isSubmitting: Bool = false
    var lastError: String?

    var coordinator: AuthCoordinator

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var authService: any AuthServiceProtocol

    var isFormValid: Bool {
        email.isValidEmail() && !password.isEmpty
    }

    init(appContainer: AppContainer,
         authService: any AuthServiceProtocol,
         coordinator: AuthCoordinator) {
        self.appContainer = appContainer
        self.authService = authService
        self.coordinator = coordinator
    }

    func signIn() async {
        guard isFormValid else { return }
        guard !isSubmitting else { return }
        //guard reachability.isConnected else { lastError = "No no no.. creotte"; return }
        lastError = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await authService.signIn(email: email, password: password)
            resetFields()
        } catch AuthServiceError.confirmationRequired {
            coordinator.pushVerifyEmail(email: email, password: password, context: .unconfirmedLogin)
            resetFields()
        } catch AuthServiceError.invalidCredentials {
            Log.error("SignInViewModel: invalid credentials")
            lastError = String(localized: "auth.error.invalid_credentials")
        } catch AuthServiceError.signInTimedOut {
            Log.error("SignInViewModel: sign-in timeout")
            lastError = String(localized: "auth.error.timeout")
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    private func resetFields() {
        email = ""
        password = ""
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

    func createVerifyEmailView(email: String, password: String, context: VerifyEmailContext) -> VerifyEmailView {
        appContainer.createVerifyEmailView(email: email, password: password, context: context)
    }
}
