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
    private var progress: DropinButton.Progress
    private let action: () -> Void
    
    init(text: LocalizedStringKey,
         systemImage: String? = nil,
         progress: DropinButton.Progress = .none,
         action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.text = text
        self.progress = progress
        self.action = action
    }
    
    var body: some View {
        DropinButton(text: text,
                     systemImage: systemImage,
                     maxWidth: .infinity,
                     background: .surface1,
                     foreground: .dropinPrimary,
                     progress: progress,
                     action: action)
    }
}

#Preview {
    VStack {
        SecondaryButton(text: "Button1", action: {})
        SecondaryButton(text: "Button2", systemImage: "magnifyingglass", action: {})
        MainButton(text: "Button3", action: {})
    }
    .padding(.horizontal, 15)
}
