//
//  BellCurveShape.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/3/26.
//

import Foundation
import SwiftUI

struct BellCurveShape: Shape {
    
    func path(in rect: CGRect) -> Path {

        var path = Path()

        // Create arrow
        var arrowPath = Path()
        let arrowLen = rect.height
        let steps: Int = 60
        var cxStep = rect.width / CGFloat(steps)
        for i in 0..<steps {
            let t = CGFloat(i) / CGFloat(steps - 1)
            var cx = cxStep * CGFloat(i)
            var cy = CGFloat.zero

            // t in [0, 1] move in [-3, 3]
            let bt = (t * 6) - 3
            let amplitude = bellCurve(bt)
            cy = amplitude * rect.height
        
            if i == 0 {
                arrowPath.move(to: CGPoint(x: cx, y: cy))
            } else {
                arrowPath.addLine(to: CGPoint(x: cx, y: cy))
            }

        }
        arrowPath.closeSubpath()
        path.addPath(arrowPath)

        return path
    }
    
    private func bellCurve(_ t: CGFloat) -> CGFloat {
        return exp(-pow(t, 2))
    }
    
}

#Preview {
    let w: CGFloat = 390
    let h: CGFloat = 350
    VStack(spacing: 0) {
        
        Rectangle()
            .fill(.red)
            .frame(width: 100, height: 50)
        BellCurveShape()
            .fill(.red)
            .frame(width: 40, height: 10)
    }
}


