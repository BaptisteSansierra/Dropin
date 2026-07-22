//
//  BackButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/7/26.
//

import SwiftUI

struct BackButton: View {

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
        BackButton(action: {
            print("go back")
        })
        .padding(32)
    }
}
