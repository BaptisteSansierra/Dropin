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

    // MARK: - Body
    var body: some View {
        ZStack() {
            Circle()
                .foregroundStyle(.white)
                .frame(width: size, height: size)
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: icoSize, height: icoSize)
                .foregroundStyle(icoColor)
        }
        .shadow(radius: 5, x: 2, y: 2)
    }

    // MARK: - init
    init(systemImage: String, size: CGFloat = 25, icoSize: CGFloat = 15, icoColor: Color = .dropinPrimary) {
        self.systemImage = systemImage
        self.size = size
        self.icoSize = icoSize
        self.icoColor = icoColor
    }
}

#Preview {
    IcoButton(systemImage: "ellipsis")
}
