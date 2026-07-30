//
//  TextButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/7/26.
//

import SwiftUI

struct TextButton: View {
    private var text: LocalizedStringKey
    private var textStyle: TextStyle
    private var preSystemImage: String? = nil
    private var preSystemImageFont: Font
    private var postSystemImage: String? = nil
    private var postSystemImageFont: Font
    private var foreground: Color?
    private var inStack: Bool
    private let action: () -> Void

    init(text: LocalizedStringKey,
         textStyle: TextStyle = .mainButton,
         preSystemImage: String? = nil,
         preSystemImageFont: Font = .bodySemibold,
         postSystemImage: String? = nil,
         postSystemImageFont: Font = .bodySemibold,
         foreground: Color? = nil,
         inStack: Bool = false,
         action: @escaping () -> Void) {
        self.text = text
        self.textStyle = textStyle
        self.preSystemImage = preSystemImage
        self.preSystemImageFont = preSystemImageFont
        self.postSystemImage = postSystemImage
        self.postSystemImageFont = postSystemImageFont
        self.foreground = foreground
        self.inStack = inStack
        self.action = action
    }

    var body: some View {
        VStack {
            Button(action: action, label: {
                ZStack {
                    if inStack {
                        // In a vertical stack with some mainButtons, it should have a fixed height/width
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.clear)
                            .frame(height: DropinApp.ui.button.height * 0.7)
                            .frame(maxWidth: .infinity)
                    }
                    HStack {
                        if let preSystemImage = preSystemImage {
                            Image(systemName: preSystemImage)
                                .font(preSystemImageFont)
                                .foregroundStyle(foreground ?? textStyle.color)
                        }
                        Text(text)
                            .textStyle(textStyle, color: foreground)
                        if let postSystemImage = postSystemImage {
                            Image(systemName: postSystemImage)
                                .font(postSystemImageFont)
                                .foregroundStyle(foreground ?? textStyle.color)
                        }
                    }
                }
            })
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    
    VStack {
        
        HStack {
            Text(verbatim: "TITLE")
                .textStyle(.body)
            Spacer()
            TextButton(text: "common.clear") { }
        }
        .padding(.top, 20)
        HStack {
            Text(verbatim: "SUBTITLE")
                .textStyle(.caption)
            Spacer()
            TextButton(text: "common.clear",
                       textStyle: .caption,
                       foreground: .dropinPrimary) { }
        }
        .padding(.top, 20)

        Spacer()
        MainButton(text: LocalizedStringKey(stringLiteral: "Action") , action: {})

        TextButton(text: "common.cancel", inStack: true) { }

        TextButton(text: "profile.delete_account",
                   postSystemImage: "chevron.right",
                   postSystemImageFont: .system(size: 12,
                                                weight: .semibold),
                   foreground: .destructive,
                   inStack: true) {}
    }
    .padding()
}
