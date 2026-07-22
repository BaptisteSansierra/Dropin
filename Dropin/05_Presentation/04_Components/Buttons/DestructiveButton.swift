//
//  DestructiveButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI

struct DestructiveButton: View {
    
    enum Style {
        case filled
        case bordered
    }

    private var text: LocalizedStringKey
    private let style: Style
    private var systemImage: String? = nil
    private var progress: DropinButton.Progress
    private let action: () -> Void

    init(text: LocalizedStringKey,
         style: Style = .filled,
         systemImage: String? = nil,
         progress: DropinButton.Progress = .none,
         action: @escaping () -> Void) {
        self.text = text
        self.style = style
        self.systemImage = systemImage
        self.progress = progress
        self.action = action
    }

    var body: some View {
        DropinButton(text: text,
                     systemImage: systemImage,
                     maxWidth: .infinity,
                     background: style == .filled ? .destructive : .surface1,
                     foreground: style == .filled ? .surface1 : .destructive,
                     stroke: style == .filled ? .fieldBorder : .destructive.opacity(0.25),
                     progress: progress,
                     action: action)
    }
}

#Preview {
    VStack {
        VStack {
            DestructiveButton(text: "common.delete",
                              style: .filled,
                              systemImage: "trash",
                              action: {})
        }
        VStack {
            DestructiveButton(text: "common.delete",
                              style: .bordered,
                              systemImage: "trash",
                              action: {})
        }
    }
    .padding(.horizontal)
}
