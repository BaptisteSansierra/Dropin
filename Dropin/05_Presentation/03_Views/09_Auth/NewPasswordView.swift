//
//  NewPasswordView.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/11/26.
//

import SwiftUI

struct NewPasswordView: View {

    private enum Field: Hashable, CaseIterable {
        case password
        case confirmPassword
        case hiddenEmail
    }

    @State private var viewModel: NewPasswordViewModel
    @FocusState private var focusedField: Field?

    init(viewModel: NewPasswordViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundPrimary.ignoresSafeArea()
                .onTapGesture { focusedField = nil }

            ScrollView {
                formView
                    .padding(.horizontal, 32)
                    .padding(.top, 80)
                    .padding(.bottom, 90)
            }
            .scrollDismissesKeyboard(.interactively)

            HStack {
                BackButton {
                    viewModel.cancel()
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
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
        VStack(spacing: 0) {

            HStack {
                iconWell(systemImage: "lock")
                Spacer()
            }
            .padding(.top, 22)

            VStack(alignment: .leading, spacing: 8) {
                Text("auth.new_password.title")
                    .textStyle(.authTitle)
                    .lineLimit(nil)
                Text("auth.new_password.subtitle_\(Text(verbatim: viewModel.email).fontWeight(.semibold))")
                    .lineLimit(nil)
                    .textStyle(.body, color: .textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)

            VStack(spacing: 12) {
                AuthTextFieldView(systemImage: "lock",
                                  text: $viewModel.password,
                                  placeholder: String(localized: "auth.field.new_password"),
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
                                      onSubmit: submitPassword)

                    if let mismatchError = viewModel.confirmPasswordError {
                        Text(mismatchError)
                            .textStyle(.formFieldError)
                            .padding(.leading, 4)
                    }
                }
                
                // Add a hidden '.emailAddress' field so password managers can link
                // new password to related account
                AuthTextFieldView(systemImage: "envelope.and.hand.raised",
                                  text: .constant(viewModel.email),
                                  placeholder: "",
                                  isSecure: false,
                                  textContentType: .emailAddress,
                                  submitLabel: .done,
                                  focusedField: $focusedField,
                                  equals: .hiddenEmail,
                                  onSubmit: {  })
                    .opacity(0)
                    .frame(height: 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .padding(.top, 24)

            Text("auth.password_hint")
                .textStyle(.cellSubtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)

            MainButton(text: "auth.new_password.submit",
                       progress: viewModel.isSubmitting ? .run(color: .surface1, replaceContent: true) : .none,
                       action: submitPassword)
            .disabled(!viewModel.isFormValid)
            .padding(.top, 20)

            if let error = viewModel.lastError {
                Text(error)
                    .textStyle(.formFieldError)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }
        }
    }

    private func iconWell(systemImage: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.surface2)
            .stroke(.textPrimary)
            .frame(width: 64, height: 64)
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(.dropinPrimary)
            }
    }

    // MARK: - actions

    /// Resigns focus on success, same reasoning as SignUpView's submitSignUp():
    /// gives iOS a clean signal to hang its "save password?" prompt on before the auth-state flip swaps this view out
    private func submitPassword() {
        Task {
            await viewModel.savePassword()
            if viewModel.lastError == nil {
                focusedField = nil
            }
        }
    }
}

#if DEBUG
struct MockNewPasswordView: View {
    var mock: MockContainer
    var body: some View {
        mock.appContainer.createNewPasswordView(email: "john.doe@nowhere.com")
    }

    init() { self.mock = MockContainer() }
}

#Preview {
    MockNewPasswordView()
}
#endif
