//
//  MainButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI

struct MainButton: View {
    
    enum Style {
        case filled
        case bordered
    }

    private var systemImage: String? = nil
    private var text: LocalizedStringKey
    private let style: Style
    private var progress: DropinButton.Progress
    private let action: () -> Void
    
    init(text: LocalizedStringKey,
         systemImage: String? = nil,
         style: Style = .filled,
         progress: DropinButton.Progress = .none,
         action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.text = text
        self.style = style
        self.progress = progress
        self.action = action
    }
    
    var body: some View {
        DropinButton(text: text,
                     systemImage: systemImage,
                     maxWidth: .infinity,
                     //background: .dropinPrimary,
                     //foreground: .surface1,
                     background: style == .filled ? .dropinPrimary : .surface1,
                     foreground: style == .filled ? .surface1 : .dropinPrimary,
                     stroke: style == .filled ? .clear : .dropinPrimary.opacity(0.25),
                     progress: progress,
                     action: action)
        .shadow(color: .dropinPrimary.opacity(0.3), radius: 20, x: 0, y: 8)
    }
}
