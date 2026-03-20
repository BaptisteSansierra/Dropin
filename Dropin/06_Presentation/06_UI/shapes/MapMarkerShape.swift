//
//  MapMarkerShape.swift
//  Dropin
//
//  Created by baptiste sansierra on 16/3/26.
//



#if false
import SwiftUI

struct MapMarkerShape: Shape {
    
    func path(in rect: CGRect) -> Path {

        let circleScale = 0.35
        let circleCenter = CGPoint(x: rect.midX, y: rect.midY)
        let circleRadius = min(rect.width * circleScale, rect.height * circleScale)

        var path = Path()


        if true {
            var cpath = Path()
            cpath.addArc(center: CGPoint(x: circleCenter.x, y: circleCenter.y),
                         radius: circleRadius,
                         startAngle: .degrees(0),
                         endAngle: .degrees(360),
                         clockwise: true)
            path.addPath(cpath)
        }

        let arrowAngle = CGFloat.pi / 4.0
        let pointA = CGPoint(x: circleCenter.x + cos(0.5 * CGFloat.pi + arrowAngle) * circleRadius,
                             y: circleCenter.y + sin(0.5 * CGFloat.pi + arrowAngle) * circleRadius)
        let pointB = CGPoint(x: circleCenter.x,
                             y: rect.height)
        let pointC = CGPoint(x: circleCenter.x + cos(0.5 * CGFloat.pi - arrowAngle) * circleRadius,
                             y: circleCenter.y + sin(0.5 * CGFloat.pi - arrowAngle) * circleRadius)

        let ctrlRadius = circleRadius * 1
        
        let ctrlAngle = arrowAngle * 0.05
        let ctrlPointA = CGPoint(x: circleCenter.x + cos(0.5 * CGFloat.pi + ctrlAngle) * ctrlRadius,
                                 y: circleCenter.y + sin(0.5 * CGFloat.pi + ctrlAngle) * ctrlRadius)

        let ctrlPointB = CGPoint(x: circleCenter.x + cos(0.5 * CGFloat.pi - ctrlAngle) * ctrlRadius,
                                 y: circleCenter.y + sin(0.5 * CGFloat.pi - ctrlAngle) * ctrlRadius)

        
//        print("CENTER : (\(circleCenter.x), \(circleCenter.y))")
//        print("pointA : (\(pointA.x), \(pointA.y))")
//        print("pointB : (\(pointB.x), \(pointB.y))")
//        print("pointC : (\(pointC.x), \(pointC.y))")

        var bPath = Path()
        
        bPath.move(to: pointA)
        /*
        bPath.addLine(to: ctrlPointA)
        bPath.addLine(to: pointB)
        bPath.addLine(to: ctrlPointB)
        bPath.addLine(to: pointC)
         */

        bPath.addQuadCurve(
            to: pointB,
            control: ctrlPointA)
        
        bPath.addQuadCurve(
            to: pointC,
            control: ctrlPointB)

        bPath.closeSubpath()

        path.addPath(bPath)

        
        return path
    }
}

#Preview {
    VStack {
        
        MapMarkerShape()
            .fill(.red)
            .frame(width: 50, height: 50)
            .border(.black)
            .overlay(alignment: .center) {
                Circle()
                    .fill(.white)
                    .frame(width: 25, height: 25)
                    .offset(y: 0)
            }
    }
}
#endif
