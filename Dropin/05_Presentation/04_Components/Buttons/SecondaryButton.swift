//
//  SecondaryButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI

struct SecondaryButton: View {
    private var text: LocalizedStringKey
    private var systemImage: String? = nil
    private var maxWidth: CGFloat
    private var action: () -> Void

    var body: some View {
        Button(action: action, label: {
            HStack(spacing: 0) {
                Spacer()
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .textStyle(.secondaryButton)
                        .padding(.trailing, 10)
                }
                Text(text)
                    .textStyle(.secondaryButton)
                    .frame(height: DropinApp.ui.button.height)
                Spacer()
            }
            .frame(maxWidth: maxWidth)
        })
    }

    init(text: LocalizedStringKey,
         systemImage: String,
         maxWidth: CGFloat = 200,
         action: @escaping () -> Void) {
        self.text = text
        self.systemImage = systemImage
        self.maxWidth = maxWidth
        self.action = action
    }

    init(text: LocalizedStringKey,
         maxWidth: CGFloat = 200,
         action: @escaping () -> Void) {
        self.text = text
        self.maxWidth = maxWidth
        self.action = action
    }
}

#Preview {
    VStack {
        SecondaryButton(text: "Button1", action: {})
        SecondaryButton(text: "Button2", systemImage: "magnifyingglass", action: {})
        MainButton(text: "Button3", action: {})
    }
}
