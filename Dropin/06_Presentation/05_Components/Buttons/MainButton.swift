//
//  MainButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI

struct MainButton: View {
    private var systemImage: String? = nil
    private var text: LocalizedStringKey
    private var maxWidth: CGFloat?
    private var background: Color
    private let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .foregroundStyle(background)
                    .frame(height: DropinApp.ui.button.height)
                if let systemImage = systemImage {
                    HStack {
                        Image(systemName: systemImage)
                            .textStyle(.mainButton)
                            .padding(.leading)
                        Text(text)
                            .textStyle(.mainButton)
                            .padding(.trailing)
                    }
                } else {
                    Text(text)
                        .textStyle(.mainButton)
                        .padding(.horizontal)
                }
            }
        })
        .frame(maxWidth: maxWidth)
    }
    
    init(text: LocalizedStringKey,
         maxWidth: CGFloat? = DropinApp.ui.button.width,
         background: Color = .dropinPrimary,
         action: @escaping () -> Void) {
        self.text = text
        self.maxWidth = maxWidth
        self.background = background
        self.action = action
    }
    
    init(systemImage: String,
         text: LocalizedStringKey,
         maxWidth: CGFloat? = DropinApp.ui.button.width,
         background: Color = .dropinPrimary,
         action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.text = text
        self.maxWidth = maxWidth
        self.background = background
        self.action = action
    }
}

#Preview {
    VStack {
        MainButton(systemImage: "tag", text: "Button1", action: {})
        MainButton(text: "Button1", action: {})
        MainButton(text: "Button2", maxWidth: 300, action: {})
        MainButton(text: "Button3", maxWidth: 100, background: .warning, action: {})
        DestructiveButton(text: "Button4", maxWidth: 100, action: {})
    }
}
