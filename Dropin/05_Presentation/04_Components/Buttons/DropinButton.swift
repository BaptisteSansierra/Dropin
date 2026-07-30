//
//  DropinButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/7/26.
//

import SwiftUI

struct DropinButton: View {
    
    enum Progress {
        case none
        case run(color: Color, replaceContent: Bool)
    }
    
    private var systemImage: String?
    private var text: LocalizedStringKey
    private var maxWidth: CGFloat?
    private var background: Color
    private var foreground: Color
    private var stroke: Color
    private let action: () -> Void
    private var progress: Progress

    init(text: LocalizedStringKey,
         systemImage: String? = nil,
         maxWidth: CGFloat? = nil,
         background: Color = .surface1,
         foreground: Color = .dropinPrimary,
         stroke: Color = .fieldBorder,
         progress: Progress = .none,
         action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.text = text
        self.maxWidth = maxWidth
        self.background = background
        self.foreground = foreground
        self.stroke = stroke
        self.progress = progress
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: action, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(background)
                        .stroke(stroke, lineWidth: 1)
                        .frame(height: DropinApp.ui.button.height)
                        .frame(maxWidth: maxWidth)
                    
                    switch progress {
                        case .none:
                            contentView
                        case .run(let color, let replaceContent):
                            if replaceContent {
                                ProgressView()
                                    .tint(color)
                            } else {
                                contentView
                            }
                    }
                    
                }
            })
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        HStack(spacing: 0) {
            let (replaceSI, progressColor) = resolve()
            if replaceSI {
                ProgressView()
                    .tint(progressColor)
            } else if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .textStyle(.mainButton, color: foreground)
                    .padding(10)
            }
            Text(text)
                .textStyle(.mainButton, color: foreground)
        }
    }
    
    private func resolve() -> (Bool, Color) {
        var replaceSI: Bool
        var progressColor = Color.clear
        switch progress {
            case .none:
                replaceSI = false
            case .run(let color, let replaceContent):
                replaceSI = !replaceContent
                progressColor = color
        }
        return (replaceSI, progressColor)
    }
}

#Preview {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()
        VStack {
            MainButton(text: "Main button", systemImage: "tag", action: {})
            MainButton(text: "Main button 2", action: {})
            SecondaryButton(text: "Secondary button", action: {})
            DestructiveButton(text: "Button4", systemImage: "trash", action: {})
            
            Divider()
                .padding(.vertical, 15)
            
            DropinButton(text: "Button A", maxWidth: 300, action: {})
            DropinButton(text: "Button B", maxWidth: 100, background: .warning, foreground: .surface1, action: {})

            TextButton(text: "profile.delete_account",
                       postSystemImage: "chevron.right",
                       foreground: .destructive,
                       inStack: true,
                       action: {})

            MainButton(text: "Thinking button 1",
                       progress: .run(color: .surface1, replaceContent: true),
                       action: {})
                .disabled(true)
            MainButton(text: "Thinking button 2",
                       progress: .run(color: .surface1, replaceContent: false),
                       action: {})
                .disabled(true)
        }
        .padding(.horizontal, 15)
    }
}
