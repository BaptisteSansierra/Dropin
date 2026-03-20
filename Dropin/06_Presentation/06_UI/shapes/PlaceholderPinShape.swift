//
//  PlaceholderPinShape.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/3/26.
//

import SwiftUI

struct PlaceholderPinShape: Shape {
    
    private let showCtrlPoints = false

    // Compute radius of the max rect inner circle
    static func fullRadius(in rect: CGRect) -> CGFloat {
        min(rect.width, rect.height) * 0.5
    }
    
    func path(in rect: CGRect) -> Path {

        var path = Path()

        let fullRadius = PlaceholderPinShape.fullRadius(in: rect)
        let radius = fullRadius * 0.3
        let coverage = (fullRadius * 2) * 0.9
        let topY = (fullRadius * 2 - coverage) * 0.5
        let bottomY = topY + coverage
        
        let center = CGPoint(x: rect.midX,
                             y: topY + radius)

        // Create circle
        var circlePath = Path()
        circlePath.addArc(center: center,
                          radius: radius,
                          startAngle: .degrees(0),
                          endAngle: .degrees(360),
                          clockwise: true)
        path.addPath(circlePath)

        // Create leg
        var ctrlPointsPath = Path()
        var legPath = Path()

        let legAmplitude = CGFloat.pi / 10
        let p1Angle = 0.5 * CGFloat.pi + legAmplitude
        let p2Angle = 0.5 * CGFloat.pi - legAmplitude

        let p1x = center.x + cos(p1Angle) * radius * 1.2
        let p1y = center.y + sin(p1Angle) * radius * 1.2
        let p1 = CGPoint(x: p1x, y: p1y)

        let p2x = center.x + cos(p2Angle) * radius * 1.3
        let p2y = center.y + sin(p2Angle) * radius * 1.3
        let p2 = CGPoint(x: p2x, y: p2y)

        let p2To3Ctr = CGPoint(x: (p1x + p2x) * 0.5,
                               y: p2y + (p2y - p1y) * 0.5 )

        let p3x = p2x - (p2x - p1x) * 0.25
        let p3y = bottomY
        let p3 = CGPoint(x: p3x, y: p3y)

        let p4x = p1x + (p2x - p1x) * 0.25
        let p4y = bottomY
        let p4 = CGPoint(x: p4x, y: p4y)

        let p3To4Ctr = CGPoint(x: (p3x + p4x) * 0.5,
                               y: bottomY + fullRadius * 0.1)

        if showCtrlPoints {
            ctrlPointsPath.addArc(center: p1,
                                  radius: 2,
                                  startAngle: .degrees(0),
                                  endAngle: .degrees(360),
                                  clockwise: true)
            ctrlPointsPath.addArc(center: p2,
                                  radius: 2,
                                  startAngle: .degrees(0),
                                  endAngle: .degrees(360),
                                  clockwise: true)
            ctrlPointsPath.addArc(center: p3,
                                  radius: 2,
                                  startAngle: .degrees(0),
                                  endAngle: .degrees(360),
                                  clockwise: true)
            ctrlPointsPath.addArc(center: p4,
                                  radius: 2,
                                  startAngle: .degrees(0),
                                  endAngle: .degrees(360),
                                  clockwise: true)
        }

        legPath.move(to: p1)
        legPath.addQuadCurve(to: p2, control: p2To3Ctr)
        //legPath.addLine(to: p2)
        legPath.addLine(to: p3)
        legPath.addQuadCurve(to: p4, control: p3To4Ctr)
        
        legPath.closeSubpath()
        
        path.addPath(legPath)
        if showCtrlPoints {
            path.addPath(ctrlPointsPath)
        }

        return path
    }
    
}

#Preview {
    let w: CGFloat = 300
    let h: CGFloat = 300
    VStack {
        ZStack {
            MapPinShape()
                .fill(.gray)
                .frame(width: w, height: h)
            PlaceholderPinShape()
                .fill(.white)
                .frame(width: w * 0.66,
                       height: h * 0.66)
                .offset(y: -h * 0.05)
        }
    }
}


