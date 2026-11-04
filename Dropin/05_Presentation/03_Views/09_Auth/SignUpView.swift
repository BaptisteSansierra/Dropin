//
//  SignUpView.swift
//  Dropin
//

import SwiftUI

struct SignUpView: View {

    private enum Field: Hashable, CaseIterable {
        case displayName
        case email
        case password
        case confirmPassword
    }

    @State private var viewModel: SignUpViewModel
    @FocusState private var focusedField: Field?

    init(viewModel: SignUpViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.backgroundPrimary.ignoresSafeArea()
                .onTapGesture { focusedField = nil }

            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        BackButton { viewModel.pop() }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("auth.create_account")
                            .textStyle(.authTitle)
                            .lineLimit(nil)
                        Text("auth.signup.subtitle")
                            .textStyle(.body, color: .textSecondary)
                            .lineLimit(nil)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 18)

                    formView
                        .padding(.top, 22)

                    Text("auth.password_hint")
                        .textStyle(.cellSubtitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 10)

                    MainButton(text: "auth.create_account",
                               progress: viewModel.isSubmitting ? .run(color: .surface1, replaceContent: true) : .none,
                               action: submitSignUp)
                    .disabled(!viewModel.isFormValid)
                    .padding(.top, 20)

                    if let error = viewModel.lastError {
                        Text(error)
                            .textStyle(.formFieldError)
                            .multilineTextAlignment(.center)
                            .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                AuthKeyboardToolbar(focusedField: $focusedField)
            }
        }
    }

    // MARK: - subviews

    private var formView: some View {
        VStack(spacing: 12) {
            AuthTextFieldView(systemImage: "person",
                              text: $viewModel.displayName,
                              placeholder: String(localized: "auth.field.display_name"),
                              textContentType: .name,
                              submitLabel: .next,
                              focusedField: $focusedField,
                              equals: .displayName,
                              onSubmit: { focusedField = .email })

            VStack(alignment: .leading, spacing: 6) {
                AuthTextFieldView(systemImage: "envelope",
                                  text: $viewModel.email,
                                  placeholder: String(localized: "common.email"),
                                  keyboardType: .emailAddress,
                                  textContentType: .username,
                                  submitLabel: .next,
                                  focusedField: $focusedField,
                                  equals: .email,
                                  onSubmit: { focusedField = .password })

                if let emailError = viewModel.emailError {
                    Text(emailError)
                        .textStyle(.formFieldError)
                        .padding(.leading, 4)
                }
            }

            AuthTextFieldView(systemImage: "lock",
                              text: $viewModel.password,
                              placeholder: String(localized: "auth.password"),
                              isSecure: true,
                              textContentType: .newPassword,
                              submitLabel: .next,
                              focusedField: $focusedField,
                              equals: .password,
                              onSubmit: { focusedField = .confirmPassword })

            VStack(alignment: .leading, spacing: 6) {
                AuthTextFieldView(systemImage: "lock",
                                  text: $viewModel.confirmPassword,
                                  placeholder: String(localized: "auth.field.confirm_password"),
                                  isSecure: true,
                                  textContentType: .newPassword,
                                  submitLabel: .go,
                                  focusedField: $focusedField,
                                  equals: .confirmPassword,
                                  onSubmit: submitSignUp)

                if let mismatchError = viewModel.confirmPasswordError {
                    Text(mismatchError)
                        .textStyle(.formFieldError)
                        .padding(.leading, 4)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text("auth.already_have_account")
                .textStyle(.body, color: .textSecondary)
            Button("auth.signin") { viewModel.pop() }
                .buttonStyle(.plain)
                .textStyle(.link)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - actions

    /// Resigns focus on success so the field's `SecureField`/`.newPassword`
    /// content cleanly resigns first responder before the auth-state flip
    /// tears down this view — without this, iOS has no clean signal to hang
    /// the "save new password?" prompt on. Shared by the primary button and
    /// the confirm-password field's keyboard submit, since either can trigger
    /// signUp().
    private func submitSignUp() {
        Task {
            await viewModel.signUp()
            if viewModel.lastError == nil {
                focusedField = nil
            }
        }
    }
}

#if DEBUG
struct MockSignUpView: View {
    var mock: MockContainer
    var body: some View {
        mock.appContainer.createSignUpView()
    }
    
    init() { self.mock = MockContainer() }
}

#Preview {
    MockSignUpView()
}
#endif
