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
    private var height: CGFloat
    private var background: Color
    private var foreground: Color
    private var stroke: Color
    private let action: () -> Void
    private var progress: Progress

    init(text: LocalizedStringKey,
         systemImage: String? = nil,
         maxWidth: CGFloat? = nil,
         height: CGFloat = DropinApp.ui.button.height,
         background: Color = .surface1,
         foreground: Color = .dropinPrimary,
         stroke: Color = .fieldBorder,
         progress: Progress = .none,
         action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.text = text
        self.maxWidth = maxWidth
        self.height = height
        self.background = background
        self.foreground = foreground
        self.stroke = stroke
        self.progress = progress
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: action, label: {
                #if false
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(background)
                        .stroke(stroke, lineWidth: 1)
                        .frame(height: height)
                        .frame(maxWidth: maxWidth)
                    
                    contentView
                    
                }
                #else
                
                contentView
                    .frame(height: height)
                    .frame(maxWidth: maxWidth)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(background)
                            .stroke(stroke, lineWidth: 1)
                    }
                #endif
            })
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch progress {
            case .none:
                buttonContentView
            case .run(let color, let replaceContent):
                if replaceContent {
                    ProgressView()
                        .tint(color)
                } else {
                    buttonContentView
                }
        }
    }

    @ViewBuilder
    private var buttonContentView: some View {
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
        .padding(.horizontal, 15)
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
            
            HStack {
                Text(verbatim: "dummy")
                Spacer()
                MainSmallButton(text: "Small Main", action: {})
                SecondarySmallButton(text: "Small 2ndry", action: {})
            }

        }
        .padding(.horizontal, 15)
    }
}
