//
//  VerifyEmailView.swift
//  Dropin
//

import SwiftUI

struct VerifyEmailView: View {

    @State private var viewModel: VerifyEmailViewModel

    init(viewModel: VerifyEmailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    badgeView
                    
                    Text("auth.verify.title")
                        .textStyle(.authTitle)
                        .multilineTextAlignment(.center)
                        .padding(.top, 26)

                    Text("auth.verify.body_\(viewModel.email)")
                        .textStyle(.body, color: .textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)

                    AuthPrimaryButton(text: "auth.verify.check_confirmation",
                                      isLoading: viewModel.isCheckingConfirmation) {
                        Task { await viewModel.checkConfirmationAndSignIn() }
                    }
                    .padding(.top, 30)

                    resendRow
                        .padding(.top, 18)

                    if let error = viewModel.lastError {
                        Text(error)
                            .textStyle(.formFieldError)
                            .multilineTextAlignment(.center)
                            .padding(.top, 12)
                    }

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 32)
                .padding(.top, 40)
                .padding(.bottom, 90)
            }

            footer
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.backgroundPrimary)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - subviews
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

    private var footer: some View {
        Button("auth.verify.change_email") { viewModel.changeEmailAddress() }
            .buttonStyle(.plain)
            .textStyle(.link)
            .frame(maxWidth: .infinity)
    }

    private var resendRow: some View {
        HStack(spacing: 4) {
            Text("auth.verify.didnt_get_it")
                .textStyle(.body, color: .textSecondary)
            if viewModel.canResend {
                Button("auth.verify.resend") { Task { await viewModel.resend() } }
                    .buttonStyle(.plain)
                    .textStyle(.link)
                    .disabled(viewModel.isResending)
            } else {
                Text("auth.verify.resend_countdown_\(viewModel.formattedCountdown)")
                    .textStyle(.body, color: .textTertiary)
            }
        }
    }

}

#if DEBUG
struct MockVerifyEmailView: View {
    var mock: MockContainer
    var body: some View {
        mock.appContainer.createVerifyEmailView(email: "bat@o.surlo", password: "hunter2")
    }

    init() { self.mock = MockContainer() }
}

#Preview {
    MockVerifyEmailView()
}
#endif
