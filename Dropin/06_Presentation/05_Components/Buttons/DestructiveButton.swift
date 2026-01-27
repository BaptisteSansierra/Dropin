//
//  DestructiveButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI

struct DestructiveButton: View {
    private var text: LocalizedStringKey
    private var maxWidth: CGFloat?
    private let action: () -> Void

    var body: some View {
        MainButton(text: text,
                   maxWidth: maxWidth,
                   background: .destructive,
                   action: action)
    }

    init(text: LocalizedStringKey,
         maxWidth: CGFloat? = DropinApp.ui.button.width,
         action: @escaping () -> Void) {
        self.text = text
        self.maxWidth = maxWidth
        self.action = action
    }
}
