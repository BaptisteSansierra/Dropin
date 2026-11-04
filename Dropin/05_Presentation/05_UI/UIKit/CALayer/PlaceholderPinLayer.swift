//
//  PlaceholderPinLayer.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/9/26.
//

import UIKit

/// UIKit/CAShapeLayer port of `PlaceholderPinShape` (SwiftUI) — same
/// circle + curved leg path math, for UIKit-hosted rendering.
final class PlaceholderPinLayer: CAShapeLayer {

    static func fullRadius(in rect: CGRect) -> CGFloat {
        min(rect.width, rect.height) * 0.5
    }

    /// Recomputes and applies `path` for the given rect — call whenever the layer's bounds change.
    func update(in rect: CGRect) {
        let fullRadius = Self.fullRadius(in: rect)
        let radius = fullRadius * 0.35
        let coverage = (fullRadius * 2) * 0.8
        let topY = (fullRadius * 2 - coverage) * 0.5
        let bottomY = topY + coverage
        let center = CGPoint(x: rect.midX, y: topY + radius)

        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: 0,
                                endAngle: .pi * 2,
                                clockwise: true)

        let legAmplitude = CGFloat.pi / 10
        let p1Angle = 0.5 * CGFloat.pi + legAmplitude
        let p2Angle = 0.5 * CGFloat.pi - legAmplitude

        let p1 = CGPoint(x: center.x + cos(p1Angle) * radius * 1.2,
                         y: center.y + sin(p1Angle) * radius * 1.2)
        let p2 = CGPoint(x: center.x + cos(p2Angle) * radius * 1.3,
                         y: center.y + sin(p2Angle) * radius * 1.3)

        let p2To3Ctr = CGPoint(x: (p1.x + p2.x) * 0.5,
                               y: p2.y + (p2.y - p1.y) * 0.5)

        let p3 = CGPoint(x: p2.x - (p2.x - p1.x) * 0.25, y: bottomY)
        let p4 = CGPoint(x: p1.x + (p2.x - p1.x) * 0.25, y: bottomY)

        let p3To4Ctr = CGPoint(x: (p3.x + p4.x) * 0.5, y: bottomY + fullRadius * 0.1)

        let legPath = UIBezierPath()
        legPath.move(to: p1)
        legPath.addQuadCurve(to: p2, controlPoint: p2To3Ctr)
        legPath.addLine(to: p3)
        legPath.addQuadCurve(to: p4, controlPoint: p3To4Ctr)
        legPath.close()

        path.append(legPath)
        self.path = path.cgPath
    }
}
