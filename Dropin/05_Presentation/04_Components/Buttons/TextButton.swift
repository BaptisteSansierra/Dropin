//
//  TextButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/7/26.
//

import SwiftUI

struct TextButton: View {
    private var text: LocalizedStringKey
    private var preSystemImage: String? = nil
    private var preSystemImageFont: Font
    private var postSystemImage: String? = nil
    private var postSystemImageFont: Font
    private var foreground: Color
    private let action: () -> Void

    init(text: LocalizedStringKey,
         preSystemImage: String? = nil,
         preSystemImageFont: Font = .bodySemibold,
         postSystemImage: String? = nil,
         postSystemImageFont: Font = .bodySemibold,
         foreground: Color = .dropinPrimary,
         action: @escaping () -> Void) {
        self.preSystemImage = preSystemImage
        self.preSystemImageFont = preSystemImageFont
        self.text = text
        self.postSystemImage = postSystemImage
        self.postSystemImageFont = postSystemImageFont
        self.foreground = foreground
        self.action = action
    }

    var body: some View {
        VStack {
            Button(action: action, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.clear)
                        .frame(height: DropinApp.ui.button.height * 0.7)
                        .frame(maxWidth: .infinity)
                    
                    HStack {
                        if let preSystemImage = preSystemImage {
                            Image(systemName: preSystemImage)
                                .font(preSystemImageFont)
                                .foregroundStyle(foreground)
                        }
                        Text(text)
                            .textStyle(.mainButton, color: foreground)
                        if let postSystemImage = postSystemImage {
                            Image(systemName: postSystemImage)
                                .font(postSystemImageFont)
                                .foregroundStyle(foreground)
                        }
                    }
                }
            })
            .buttonStyle(.plain)
        }
    }
}

