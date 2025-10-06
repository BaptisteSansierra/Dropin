//
//  DropinLogo.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/8/25.
//

import SwiftUI

/// The logo: circle with circles
struct DropinLogo: View {

    // MARK: - private vars
    private var c0: Color = .dropinPrimary
    private var c1: Color = .dropinSecondary
    private var c2: Color = Color(rgba: "f28f3b")
    private var c3: Color = Color(rgba: "007ea7")
    private var lineWidthMuliplier: CGFloat = 1
    private var pinSizeMuliplier: CGFloat = 1

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            Circle()
                .stroke(c0, lineWidth: size * 0.04 * lineWidthMuliplier)
                .overlay {
                    InCircle(color: c1, size: size * 0.07 * pinSizeMuliplier)
                        .offset(x: 0.1 * size, y: -0.25 * size)
                    InCircle(color: c1, size: size * 0.07 * pinSizeMuliplier)
                        .offset(x: 0.25 * size, y: -0.2 * size)
                    InCircle(color: c2, size: size * 0.07 * pinSizeMuliplier)
                        .offset(x: 0.14 * size, y: -0.1 * size)
                    InCircle(color: c1, size: size * 0.07 * pinSizeMuliplier)
                        .offset(x: -0.1 * size, y: 0.3 * size)
                    InCircle(color: c3, size: size * 0.07 * pinSizeMuliplier)
                        .offset(x: -0.25 * size, y: 0.1 * size)
                }
        }
    }
    
    // MARK: - init
   init(lineWidthMuliplier: CGFloat = 1, pinSizeMuliplier: CGFloat = 1) {
        self.lineWidthMuliplier = lineWidthMuliplier
        self.pinSizeMuliplier = pinSizeMuliplier
    }
}

fileprivate struct InCircle: View {
    
    // MARK: - private vars
    private var color: Color
    private var size: CGFloat
    
    // MARK: - Body
    var body: some View {
        Circle()
            .foregroundStyle(color)
            .frame(width: size, height: size)
    }
    
    // MARK: - init
    init(color: Color, size: CGFloat) {
        self.color = color
        self.size = size
    }
}

#Preview {
    DropinLogo()
}
