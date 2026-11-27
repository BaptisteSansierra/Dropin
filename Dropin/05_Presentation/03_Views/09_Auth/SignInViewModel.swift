//
//  SignInViewModel.swift
//  Dropin
//

import Foundation
import AuthenticationServices

@MainActor
@Observable class SignInViewModel {

    #if false 
    var email: String = AppConfig.DebugCredentials.email          // Config.xcconfig: DEBUG_SIGNIN_ACCOUNT
    var password: String = AppConfig.DebugCredentials.password
    #else
    var email: String = ""
    var password: String = ""
    #endif
    var isSubmitting: Bool = false
    var lastError: String?
    var lastAppleError: String?

    var coordinator: AuthCoordinator

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var authService: any AuthServiceProtocol
    /// Raw nonce of the pending Apple request, its SHA256 was sent to Apple
    @ObservationIgnored private var appleNonce: String?

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
        lastAppleError = nil
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

    func createNewPasswordView(email: String) -> NewPasswordView {
        appContainer.createNewPasswordView(email: email)
    }
    
    // MARK: - Apple signin
    /// Sets the scopes and the hashed nonce, keeps the raw nonce for Supabase
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleNonce.random()
        appleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleNonce.sha256(nonce)
    }

    /// Sends the ID token + raw nonce to authService.signInWithApple(idToken:nonce:),
    /// sets the display name from the full name (first sign-in only), ignores a canceled sheet
    func signInWithApple(_ result: Result<ASAuthorization, Error>) async {
        lastError = nil
        lastAppleError = nil
        guard !isSubmitting else { return }
        let nonce = appleNonce
        appleNonce = nil

        let authorization: ASAuthorization
        switch result {
            case .success(let value):
                authorization = value
            case .failure(let error as ASAuthorizationError) where error.code == .canceled:
                Log.info("SignInViewModel: Apple sign-in canceled")
                return
            case .failure(let error):
                Log.error("SignInViewModel: Apple authorization failed: \(error)")
                lastAppleError = String(localized: "auth.error.apple_signin_failed")
                return
        }
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce else {
            Log.error("SignInViewModel: Apple credential without identity token or nonce")
            lastAppleError = String(localized: "auth.error.apple_signin_failed")
            return
        }

        await completeAppleSignIn(idToken: idToken, nonce: nonce, fullName: credential.fullName)
    }

    /// Second half of `signInWithApple(_:)`, once the Apple credential is unpacked
    /// (internal: `ASAuthorization` can't be built in tests)
    func completeAppleSignIn(idToken: String, nonce: String, fullName: PersonNameComponents?) async {
        lastAppleError = nil
        isSubmitting = true
        defer { isSubmitting = false }
        // Apple only gives the full name on the first sign-in: stashed before signing in,
        // `loadProfile()` runs as soon as the session is set and only uses it if the profile has no name
        let displayName = fullName.map {
            PersonNameComponentsFormatter.localizedString(from: $0, style: .default)
        }
        if let displayName, !displayName.isEmpty {
            appContainer.pendingDisplayName = displayName
        }
        do {
            try await authService.signInWithApple(idToken: idToken, nonce: nonce)
            resetFields()
        } catch AuthServiceError.signInTimedOut {
            appContainer.pendingDisplayName = nil
            Log.error("SignInViewModel: Apple sign-in timeout")
            lastAppleError = String(localized: "auth.error.timeout")
        } catch {
            appContainer.pendingDisplayName = nil
            lastAppleError = error.localizedDescription
        }
    }
}
