//
//  SignInView.swift
//  Dropin
//
//  Root of the auth flow (shown by DropinApp when no session is restored).
//  Hosts the NavigationStack for Sign up / Reset password / Verify email.
//

import SwiftUI

struct SignInView: View {

    private enum Field: Hashable, CaseIterable {
        case email
        case password
    }

    @State private var viewModel: SignInViewModel
    @FocusState private var focusedField: Field?

    init(viewModel: SignInViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            ZStack(alignment: .bottom) {
                Color.backgroundPrimary.ignoresSafeArea()
                    .onTapGesture { focusedField = nil }

                ScrollView {
                    VStack(spacing: 0) {
                        brandHeader

                        VStack(alignment: .leading, spacing: 6) {
                            Text("auth.welcome_back")
                                .textStyle(.authTitle)
                                .lineLimit(nil)
                            Text("auth.signin.subtitle")
                                .textStyle(.body, color: .textSecondary)
                                .lineLimit(nil)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 38)

                        formView
                            .padding(.top, 26)

                        HStack {
                            Spacer()
                            Button("auth.forgot_password") {
                                print("FORGETETET")
                                viewModel.pushResetPassword()
                            }
                            .buttonStyle(.plain)
                            .textStyle(.link)
                        }
                        .padding(.top, 12)

                        MainButton(text: "auth.signin",
                                   progress: viewModel.isSubmitting ? .run(color: .backgroundPrimary, replaceContent: true) : .none,
                                   action: submitSignIn)
//                        AuthPrimaryButton(text: "auth.signin",
//                                          isLoading: viewModel.isSubmitting,
//                                          action: submitSignIn)
                        .disabled(!viewModel.isFormValid)
                        .padding(.top, 22)

                        if let error = viewModel.lastError {
                            Text(error)
                                .textStyle(.formFieldError)
                                .multilineTextAlignment(.center)
                                .padding(.top, 12)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                    .padding(.bottom, 90)
                }
                .scrollDismissesKeyboard(.interactively)

                footer
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(.backgroundPrimary)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .opacity(focusedField == nil ? 1 : 0)
                    .allowsHitTesting(focusedField == nil)
                    .animation(.easeInOut(duration: 0.2), value: focusedField)
            }
            .navigationDestination(for: AuthNavigationItem.self) { item in
                resolveDestination(item)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    AuthKeyboardToolbar(focusedField: $focusedField)
                }
            }
        }
    }

    // MARK: - subviews

    private var brandHeader: some View {
        VStack(spacing: 14) {
            DropinLogo(variant: .logo)
                .frame(width: 64, height: 64)
            Text(verbatim: DropinApp.strings.app)
                .font(.title3Bold)
                .foregroundStyle(.textPrimary)
                .tracking(0.2)
        }
        .padding(.top, 14)
    }

    private var formView: some View {
        VStack(spacing: 12) {
            AuthTextFieldView(systemImage: "envelope",
                              text: $viewModel.email,
                              placeholder: String(localized: "common.email"),
                              keyboardType: .emailAddress,
                              textContentType: .username,
                              submitLabel: .next,
                              focusedField: $focusedField,
                              equals: .email,
                              onSubmit: { focusedField = .password })

            AuthTextFieldView(systemImage: "lock",
                              text: $viewModel.password,
                              placeholder: String(localized: "auth.password"),
                              isSecure: true,
                              textContentType: .password,
                              submitLabel: .go,
                              focusedField: $focusedField,
                              equals: .password,
                              onSubmit: submitSignIn)
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text("auth.new_to_dropin")
                .textStyle(.body, color: .textSecondary)
            Button("auth.create_account") { viewModel.pushSignUp() }
                .buttonStyle(.plain)
                .textStyle(.link)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func resolveDestination(_ item: AuthNavigationItem) -> some View {
        switch item {
            case .signUp:
                viewModel.createSignUpView()
            case .resetPassword:
                viewModel.createResetPasswordView()
            case .verifyEmail(let email, let password, let context):
                viewModel.createVerifyEmailView(email: email, password: password, context: context)
        }
    }

    // MARK: - actions

    /// Resigns focus on success, same reasoning as SignUpView's
    /// submitSignUp(): give iOS a clean first-responder resignation to hang
    /// its save/update-password prompt on before the auth-state flip swaps
    /// this whole view out for RootView.
    private func submitSignIn() {
        Task {
            await viewModel.signIn()
            if viewModel.lastError == nil {
                focusedField = nil
            }
        }
    }
}

#if DEBUG
struct MockAuthView: View {
    var mock: MockContainer
    var body: some View {
        mock.appContainer.createSignInView()
    }
    init() { self.mock = MockContainer() }
}

#Preview {
    MockAuthView()
}
#endif
