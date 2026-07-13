//
//  AuthBackButton.swift
//  Dropin
//
//  Circular back-chevron used atop the Sign up / Reset password screens,
//  replacing the system back button per the auth design spec.
//

import SwiftUI

struct AuthBackButton: View {

    private let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
            .fill(.surface2)
            .stroke(.fieldBorder)
            .frame(width: 36, height: 36)
            .overlay {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.textSecondary)
            }
        }
    }

    init(action: @escaping () -> Void) {
        self.action = action
    }
}

#Preview {
    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        AuthBackButton(action: {
            print("go back")
        })
        .padding(32)
    }
}
