//
//  BellCurve.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/9/26.
//

import CoreGraphics

/// Shared math behind `BellCurveShape` (SwiftUI): a gaussian-ish falloff curve
/// used to taper the arrow/pointer shapes. `MapPinShape`'s arrow and
/// `BellCurveShape`'s tail apply this formula differently — one modulates a
/// polar radius along an arc, the other a cartesian height along a straight
/// line — so it's the formula that's shared here, not a single path generator.
enum BellCurve {
    static func amplitude(_ t: CGFloat) -> CGFloat {
        exp(-pow(t, 2))
    }

    static func lerp(_ t: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        guard t >= 0 else { return a }
        guard t <= 1 else { return b }
        return (1 - t) * a + t * b
    }
}
