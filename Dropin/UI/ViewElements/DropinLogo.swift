//
//  DropinLogo.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/8/25.
//

import SwiftUI

struct DropinLogo: View {

    var c0: Color = .dropinPrimary
    var c1: Color = .dropinSecondary
    var c2: Color = Color(rgba: "f28f3b")
    var c3: Color = Color(rgba: "007ea7")
    var lineWidthMuliplier: CGFloat = 1
    var pinSizeMuliplier: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            Circle()
                .stroke(c0, lineWidth: size * 0.04 * lineWidthMuliplier)
                .overlay {
                    CCircle(color: c1, size: size * 0.07 * pinSizeMuliplier)
                        .offset(x: 0.1 * size, y: -0.25 * size)
                    CCircle(color: c1, size: size * 0.07 * pinSizeMuliplier)
                        .offset(x: 0.25 * size, y: -0.2 * size)
                    CCircle(color: c2, size: size * 0.07 * pinSizeMuliplier)
                        .offset(x: 0.14 * size, y: -0.1 * size)
                    CCircle(color: c1, size: size * 0.07 * pinSizeMuliplier)
                        .offset(x: -0.1 * size, y: 0.3 * size)
                    CCircle(color: c3, size: size * 0.07 * pinSizeMuliplier)
                        .offset(x: -0.25 * size, y: 0.1 * size)
                }
        }
    }
    
    init(lineWidthMuliplier: CGFloat = 1, pinSizeMuliplier: CGFloat = 1) {
        self.lineWidthMuliplier = lineWidthMuliplier
        self.pinSizeMuliplier = pinSizeMuliplier
    }
}

struct CCircle: View {
    var color: Color
    var size: CGFloat
    
    var body: some View {
        Circle()
//            .stroke(color, lineWidth: 2)
//            .frame(width: 8, height: 8)
            .foregroundStyle(color)
            .frame(width: size, height: size)
//            .shadow(radius: 1, x: 0, y: 3)
    }
    
    init(color: Color, size: CGFloat) {
        self.color = color
        self.size = size
    }
}

#Preview {
    DropinLogo()
}
