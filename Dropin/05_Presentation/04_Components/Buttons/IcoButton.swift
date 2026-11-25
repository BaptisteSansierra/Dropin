//
//  IcoButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

/// A SF Symbol in a circle, used over the app as a button
struct IcoButton: View {
    
    // MARK: - private vars
    private var systemImage: String
    private var size: CGFloat = 25
    private var icoSize: CGFloat = 15
    private var icoColor: Color = .dropinPrimary
    private var action: () -> Void

    // MARK: - Body
    var body: some View {
        Button(action: action, label: {
            content
        })
    }

    private var content: some View {
        ZStack() {
            Circle()
                .foregroundStyle(.backgroundPrimary)
                .frame(width: size, height: size)
                .shadow(color: .textPrimary.opacity(0.5),
                        radius: 5,
                        x: 2,
                        y: 2)
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: icoSize, height: icoSize)
                .foregroundStyle(icoColor)
        }
    }

    // MARK: - init
    init(systemImage: String,
         size: CGFloat = 25,
         icoSize: CGFloat = 15,
         icoColor: Color = .dropinPrimary,
         action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.size = size
        self.icoSize = icoSize
        self.icoColor = icoColor
        self.action = action
    }
}

#Preview {
    IcoButton(systemImage: "ellipsis", action: {})
}
