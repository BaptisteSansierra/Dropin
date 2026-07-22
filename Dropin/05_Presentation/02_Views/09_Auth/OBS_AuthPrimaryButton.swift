//
//  AuthPrimaryButton.swift
//  Dropin
//
//  Full-width primary CTA for the auth flow: 14pt radius, dropinPrimary fill,
//  soft teal shadow. Deliberately not the shared `MainButton` (radius 8) —
//  the auth redesign's radius is scoped to these 4 screens for now, not an
//  app-wide button restyle.
//

#if false

import SwiftUI

struct AuthPrimaryButton: View {

    @Environment(\.isEnabled) private var isEnabled

    private let text: LocalizedStringKey
    private let isLoading: Bool
    private let action: () -> Void

    var body: some View {
        VStack {
            MainButton(text: text,
                       progress: isLoading ? .run(color: .backgroundPrimary, replaceContent: true) : .none,
                       action: action)
            
            Button(action: action) {
                ZStack {
                    Text(text)
                        //.textStyle(.mainButton)
                        .foregroundStyle(.white)
                        .opacity(isLoading ? 0 : 1)
                    if isLoading {
                        ProgressView()
                            .tint(.backgroundPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.dropinPrimary, in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: .dropinPrimary.opacity(0.3), radius: 20, x: 0, y: 8)
            }
            .disabled(!isEnabled || isLoading)
            .opacity(isEnabled ? 1 : 0.5)
        }
    }

    init(text: LocalizedStringKey,
         isLoading: Bool = false,
         action: @escaping () -> Void) {
        self.text = text
        self.isLoading = isLoading
        self.action = action
    }
}

#Preview {
    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: 16) {
            AuthPrimaryButton(text: "Sign in", action: {})
                .padding(.bottom, 20)
            AuthPrimaryButton(text: "Sign in", isLoading: true, action: {})
                .padding(.bottom, 20)
            AuthPrimaryButton(text: "Sign in", action: {})
                .disabled(true)
                .padding(.bottom, 20)
        }
        .padding(32)
    }
}

#endif
