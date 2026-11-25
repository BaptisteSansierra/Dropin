//
//  MainSmallButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 22/9/26.
//

import SwiftUI

struct MainSmallButton: View {
    
    private var systemImage: String? = nil
    private var text: LocalizedStringKey
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
        MainButton(text: text,
                   systemImage: systemImage,
                   progress: progress,
                   maxWidth: nil,
                   height: DropinApp.ui.button.smallHeight,
                   action: action)
    }
}
