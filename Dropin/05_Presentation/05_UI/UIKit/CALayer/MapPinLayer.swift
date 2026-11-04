//
//  MapPinLayer.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/9/26.
//

import UIKit

/// UIKit/CAShapeLayer port of `MapPinShape` (SwiftUI) — same balloon-pin path
/// math, for UIKit-hosted annotation views where a SwiftUI `Shape` isn't available.
final class MapPinLayer: CAShapeLayer {

    static private let radiusRatio: CGFloat = 0.9

    static func fullRadius(in rect: CGRect) -> CGFloat {
        min(rect.width, rect.height) * 0.5
    }

    static func radius(in rect: CGRect) -> CGFloat {
        fullRadius(in: rect) * radiusRatio
    }

    static func center(in rect: CGRect) -> CGPoint {
        let x = rect.midX
        let fullRadius = fullRadius(in: rect)
        let radius = radius(in: rect)
        var y = rect.midY
        y += (rect.size.height - 2 * radius) * 0.5
        y -= fullRadius * (1 - radiusRatio) * 2
        return CGPoint(x: x, y: y)
    }

    /// Recomputes and applies `path` for the given rect — call whenever the layer's bounds change.
    func update(in rect: CGRect) {
        let fullRadius = Self.fullRadius(in: rect)
        let radius = Self.radius(in: rect)
        let center = Self.center(in: rect)

        // clockwise: false — matches the arrow subpath's winding direction below
        // (built by hand from raw trig points, not via this initializer's own
        // clockwise flag). SwiftUI's Path.addArc sweeps the opposite visual
        // direction for the same `clockwise` flag, so a direct `true` port from
        // MapPinShape leaves this subpath winding opposite the arrow — under the
        // default nonZero fill rule that cancels instead of unions, punching a
        // hole where the two subpaths overlap.
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: 0,
                                endAngle: .pi * 2,
                                clockwise: false)

        let arrowAngle = CGFloat.pi / 8
        let arrowLen = (fullRadius - radius) * 2
        let steps = 60
        let startAngle = 0.5 * CGFloat.pi + arrowAngle
        let endAngle = 0.5 * CGFloat.pi - arrowAngle

        let arrowPath = UIBezierPath()
        for i in 0..<steps {
            let t = CGFloat(i) / CGFloat(steps - 1)
            let cAngle = BellCurve.lerp(t, startAngle, endAngle)
            let bt = t < 0.5 ? (t * 6) - 3 : (t - 0.5) * 6
            let cRadius = BellCurve.lerp(BellCurve.amplitude(bt), radius, radius + arrowLen)
            let point = CGPoint(x: center.x + cos(cAngle) * cRadius,
                                y: center.y + sin(cAngle) * cRadius)
            if i == 0 {
                arrowPath.move(to: point)
            } else {
                arrowPath.addLine(to: point)
            }
        }
        arrowPath.close()

        path.append(arrowPath)
        self.path = path.cgPath
    }
}
