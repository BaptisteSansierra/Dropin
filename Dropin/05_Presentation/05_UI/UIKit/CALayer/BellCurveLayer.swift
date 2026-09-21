//
//  BellCurveLayer.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/9/26.
//

import UIKit

/// UIKit/CAShapeLayer port of `BellCurveShape` (SwiftUI) — a horizontal
/// gaussian-falloff strip, used as the tail/pointer under `PlaceRectAnnotationLayerView`.
final class BellCurveLayer: CAShapeLayer {

    /// Recomputes and applies `path` for the given rect — call whenever the layer's bounds change.
    func update(in rect: CGRect) {
        let path = UIBezierPath()
        let steps = 60
        let cxStep = rect.width / CGFloat(steps)

        for i in 0..<steps {
            let t = CGFloat(i) / CGFloat(steps - 1)
            let cx = cxStep * CGFloat(i)
            let bt = (t * 6) - 3
            let cy = BellCurve.amplitude(bt) * rect.height
            let point = CGPoint(x: cx, y: cy)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        self.path = path.cgPath
    }
}
