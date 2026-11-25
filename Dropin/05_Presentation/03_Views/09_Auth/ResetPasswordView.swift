//
//  ResetPasswordView.swift
//  Dropin
//

import SwiftUI

struct ResetPasswordView: View {

    private enum Field: Hashable, CaseIterable {
        case email
    }

    @State private var viewModel: ResetPasswordViewModel
    @FocusState private var focusedField: Field?

    init(viewModel: ResetPasswordViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.backgroundPrimary.ignoresSafeArea()
                .onTapGesture { focusedField = nil }

            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isSent {
                        sentView
                    } else {
                        formView
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 80)
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

            VStack(spacing: 0) {
                HStack {
                    BackButton {
                        viewModel.pop()
                    }
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 24)
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isSent)
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
                Text("auth.reset.title")
                    .textStyle(.authTitle)
                    .lineLimit(nil)
                Text("auth.reset.subtitle")
                    .lineLimit(nil)
                    .textStyle(.body, color: .textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)

            AuthTextFieldView(systemImage: "envelope",
                              text: $viewModel.email,
                              placeholder: String(localized: "common.email"),
                              keyboardType: .emailAddress,
                              textContentType: .username,
                              submitLabel: .go,
                              focusedField: $focusedField,
                              equals: .email,
                              onSubmit: { Task { await viewModel.sendResetLink() } })
            .padding(.top, 24)

            MainButton(text: "auth.reset.submit",
                       progress: viewModel.isSubmitting ? .run(color: .surface1, replaceContent: true) : .none) {
                Task { await viewModel.sendResetLink() }
            }
//            AuthPrimaryButton(text: "auth.reset.submit",
//                              isLoading: viewModel.isSubmitting) {
//                Task { await viewModel.sendResetLink() }
//            }
            .disabled(!viewModel.isFormValid)
            .padding(.top, 22)

            if let error = viewModel.lastError {
                Text(error)
                    .textStyle(.formFieldError)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }
        }
    }

    private var sentView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            badgeView
            
            Text("auth.reset.sent_title")
                .textStyle(.authTitle)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .padding(.top, 26)

            Text("auth.reset.sent_body_\(viewModel.email)")
                .textStyle(.body, color: .textSecondary)
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .padding(.top, 10)

            Spacer(minLength: 40)
        }
    }
    
    private var badgeView: some View {
        Circle()
            .fill(.surface2)
            .frame(width: 96, height: 96)
            .overlay {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(.dropinPrimary)
            }
            .shadow(color: .black.opacity(0.1),
                    radius: 10,
                    x: 0,
                    y: 5)
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

    private var footer: some View {
        HStack(spacing: 4) {
            Text("auth.remembered_it")
                .textStyle(.body, color: .textSecondary)
            Button("auth.signin") { viewModel.pop() }
                .buttonStyle(.plain)
                .textStyle(.link)
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
struct MockResetPasswordView: View {
    var mock: MockContainer
    var body: some View {
        mock.appContainer.createResetPasswordView()
    }
    
    init() { self.mock = MockContainer() }
}

#Preview {
    MockResetPasswordView()
}
#endif
