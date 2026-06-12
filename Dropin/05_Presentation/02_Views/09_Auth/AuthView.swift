//
//  AuthView.swift
//  Dropin
//
//  Shown by DropinApp when no session is restored. Currently a one-button
//  dev sign-in; a real email/password form will replace it once auth UI is
//  designed.
//

import SwiftUI

struct AuthView: View {

    @State private var viewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                DropinLogo(variant: .logo)
                    .frame(width: 120, height: 120)

                Text(verbatim: DropinApp.strings.app)
                    .textStyle(.title)
                    .foregroundStyle(.dropinPrimary)

                Spacer()

                if let error = viewModel.lastError {
                    Text(error)
                        .textStyle(.bodyError)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button(action: {
                    Task { await viewModel.signInDevUser() }
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isSigningIn {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(verbatim: "Sign in (dev)")
                            .textStyle(.mainButton)
                    }
                    .frame(width: DropinApp.ui.button.width,
                           height: DropinApp.ui.button.height)
                    .background(.dropinPrimary, in: Capsule())
                    .foregroundStyle(.white)
                }
                .disabled(viewModel.isSigningIn)
                .padding(.bottom, 60)
            }
        }
    }
}

#if DEBUG
struct MockAuthView: View {
    var mock: MockContainer
    var body: some View {
        mock.appContainer.createAuthView()
    }
    init() { self.mock = MockContainer() }
}

#Preview {
    MockAuthView()
}
#endif
