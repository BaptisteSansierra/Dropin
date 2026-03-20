//
//  MapPinShape.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/3/26.
//

import Foundation
import SwiftUI

struct MapPinShape: Shape {
    
    static private let radiusRatio = 0.9

    // Compute radius of the max rect inner circle
    static func fullRadius(in rect: CGRect) -> CGFloat {
        min(rect.width, rect.height) * 0.5
    }

    // Compute circle radius
    static func radius(in rect: CGRect) -> CGFloat {
        MapPinShape.fullRadius(in: rect) * MapPinShape.radiusRatio
    }
    
    // Compute circle center
    static func center(in rect: CGRect) -> CGPoint {
        let x = rect.midX
        let fullRadius = fullRadius(in: rect)
        let radius = radius(in: rect)
        var y = rect.midY
        y += (rect.size.height - 2 * radius) * 0.5
        y -= fullRadius * (1 - radiusRatio) * 2
        return CGPoint(x: x, y: y)
    }

    func path(in rect: CGRect) -> Path {

        var path = Path()

        let fullRadius = MapPinShape.fullRadius(in: rect)
        let radius = fullRadius * MapPinShape.radiusRatio
        let center = MapPinShape.center(in: rect)
        let addCtrlPoints = false

        // Create circle
        var circlePath = Path()
        circlePath.addArc(center: center,
                          radius: radius,
                          startAngle: .degrees(0),
                          endAngle: .degrees(360),
                          clockwise: true)
        path.addPath(circlePath)

        // Create arrow
        var ctrlPointsPath = Path()
        var arrowPath = Path()
        let arrowAngle = CGFloat.pi / 8
        let arrowLen = (fullRadius - radius) * 2
        let steps: Int = 60
        let startAngle = 0.5 * CGFloat.pi + arrowAngle
        let endAngle = 0.5 * CGFloat.pi - arrowAngle
        for i in 0..<steps {
            let t = CGFloat(i) / CGFloat(steps - 1)
            var cx = CGFloat.zero
            var cy = CGFloat.zero
            let cAngle = lerp(t, startAngle, endAngle)
            
            if t < 0.5 {          // Increasing
                // t in [0, 0.5] move it to [-3, 0]
                let bt = (t * 6) - 3
                let cRadius = lerp(bellCurve(bt), radius, radius + arrowLen)
                cx = center.x + cos(cAngle) * cRadius
                cy = center.y + sin(cAngle) * cRadius
            } else {              // Decreasing
                // t in [0.5, 1] move it to [0, 3]
                let bt = ((t - 0.5) * 6)
                let cRadius = lerp(bellCurve(bt), radius, radius + arrowLen)


                cx = center.x + cos(cAngle) * cRadius
                cy = center.y + sin(cAngle) * cRadius
            }
            if addCtrlPoints {
                ctrlPointsPath.addArc(center: CGPoint(x: cx, y: cy),
                                      radius: 2,
                                      startAngle: .degrees(0),
                                      endAngle: .degrees(360),
                                      clockwise: true)
            }
            if i == 0 {
                arrowPath.move(to: CGPoint(x: cx, y: cy))
            } else {
                arrowPath.addLine(to: CGPoint(x: cx, y: cy))
            }

        }
        arrowPath.closeSubpath()
        path.addPath(arrowPath)
        if addCtrlPoints {
            path.addPath(ctrlPointsPath)
        }

        return path
    }
    
    private func bellCurve(_ t: CGFloat) -> CGFloat {
        return exp(-pow(t, 2))
    }
    
    private func lerp(_ t: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        guard t >= 0 else { return a }
        guard t <= 1 else { return b }
        return (1 - t) * a + t * b
    }
}

#Preview {
    let w: CGFloat = 390
    let h: CGFloat = 350
    VStack {
        ZStack {
            Rectangle()
                .frame(width: w, height: h)
            MapPinShape()
                .fill(.red)
                .frame(width: w, height: h)
        }
    }
}


