//
//  Bubble.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/25.
//

import SwiftUI

/// Draw a comic bubble shape
struct Bubble: Shape {
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = rect.width * 0.15

        let triangleH = rect.height * 0.2
        let triangleW = rect.width * 0.25
        let triangleXAxisRelPos = 0.5
        let triangleBottom = CGPoint(x: triangleXAxisRelPos * rect.width, y: rect.maxY)
        let triangleTopLeft = CGPoint(x: triangleXAxisRelPos * rect.width, y: rect.maxY - triangleH)
        let triangleTopRight = CGPoint(x: triangleXAxisRelPos * rect.width + triangleW, y: rect.maxY - triangleH)

        let rectBottomLeft = CGPoint(x: rect.minX, y: rect.maxY - triangleH)
        let rectTopLeft = CGPoint(x: rect.minX, y: rect.minY)
        let rectTopRight = CGPoint(x: rect.maxX, y: rect.minY)
        let rectBottomRight = CGPoint(x: rect.maxX, y: rect.maxY - triangleH)

        // Start on triangle bottom
        path.move(to: triangleBottom)
        path.addLine(to: triangleTopLeft)
        
        // Bottom left
        let blP1 = CGPoint(x: rectBottomLeft.x + cornerRadius, y: rectBottomLeft.y)
        let blP2 = CGPoint(x: rectBottomLeft.x, y: rectBottomLeft.y - cornerRadius)
        path.addLine(to: blP1)
        path.addQuadCurve(to: blP2, control: rectBottomLeft)
        path.addLine(to: blP2)

        // Top left
        let tlP1 = CGPoint(x: rectTopLeft.x, y: rectTopLeft.y + cornerRadius)
        let tlP2 = CGPoint(x: rectTopLeft.x + cornerRadius, y: rectTopLeft.y)
        path.addLine(to: tlP1)
        path.addQuadCurve(to: tlP2, control: rectTopLeft)
        path.addLine(to: tlP2)

        // Top right
        let trP1 = CGPoint(x: rectTopRight.x - cornerRadius, y: rectTopRight.y)
        let trP2 = CGPoint(x: rectTopRight.x, y: rectTopRight.y + cornerRadius)
        path.addLine(to: trP1)
        path.addQuadCurve(to: trP2, control: rectTopRight)
        path.addLine(to: trP2)

        // Bottom right
        let brP1 = CGPoint(x: rectBottomRight.x, y: rectBottomRight.y - cornerRadius)
        let brP2 = CGPoint(x: rectBottomRight.x - cornerRadius, y: rectBottomRight.y)
        path.addLine(to: brP1)
        path.addQuadCurve(to: brP2, control: rectBottomRight)
        path.addLine(to: brP2)

        // End the triangle
        path.addLine(to: triangleTopRight)
        path.addLine(to: triangleBottom)

        return path
    }
}

#Preview {
    Bubble()
        .fill(.gray.opacity(0.2))
        .stroke(.black)
        .frame(width: 100, height: 100)
}
