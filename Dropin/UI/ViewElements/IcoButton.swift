//
//  IcoButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

struct IcoButton: View {
    
    var systemImage: String
    var size: CGFloat = 25
    var icoSize: CGFloat = 15
    var icoColor: Color = .dropinPrimary

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

    init(systemImage: String, size: CGFloat = 25, icoSize: CGFloat = 15, icoColor: Color = .dropinPrimary) {
        self.systemImage = systemImage
        self.size = size
        self.icoSize = icoSize
        self.icoColor = icoColor
    }
}

