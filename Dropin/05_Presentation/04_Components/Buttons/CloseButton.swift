//
//  CloseButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/7/26.
//

import SwiftUI

struct CloseButton: View {

    private let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
            .fill(.surface2)
            .stroke(.fieldBorder)
            .frame(width: 36, height: 36)
            .overlay {
                Image(systemName: "multiply")
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
        CloseButton(action: {
            print("close")
        })
        .padding(32)
    }
}
