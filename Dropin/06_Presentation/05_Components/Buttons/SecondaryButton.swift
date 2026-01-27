//
//  SecondaryButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI

struct SecondaryButton: View {
    private var text: LocalizedStringKey
    private var maxWidth: CGFloat
    private var action: () -> Void

    var body: some View {
        Button(action: action, label: {
            Text(text)
                .textStyle(.secondaryButton)
                .frame(height: DropinApp.ui.button.height)
                .frame(maxWidth: maxWidth)
        })
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
        SecondaryButton(text: "Button2", action: {})
        MainButton(text: "Button3", action: {})
    }
}
