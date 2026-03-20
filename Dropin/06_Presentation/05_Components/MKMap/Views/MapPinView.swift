//
//  MapPinView.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/3/26.
//

import SwiftUI

struct MapPinView: View {
    
    @State private var contentRadius: CGFloat = .zero
    @State private var contentOffsetY: CGFloat = .zero
    @State private var fontSize: CGFloat = .zero
    @State private var iconColor: Color = .white

    private let shapeColor: Color = .white
    private var color: Color
    private var icon: Icon?

    init(color: Color = .gray,
         icon: Icon? = nil) {
        self.color = color
        self.icon = icon
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                MapPinShape()
                    .fill(shapeColor)
                    .shadow(radius: 5)
                Circle()
                    .fill(gradient())
                    .frame(width: contentRadius * 2, height: contentRadius * 2)
                    .offset(y: contentOffsetY)
                if let icon = icon {
                    IconView(icon: icon)
                        .font(.system(size: fontSize))
                        .foregroundStyle(iconColor)
                        .offset(y: contentOffsetY)
                } else {
                    PlaceholderPinShape()
                        .frame(width: contentRadius * 1.3,
                               height: contentRadius * 1.3)
                        .foregroundStyle(iconColor)
                        .offset(y: contentOffsetY)
                }
            }
            .onAppear {
                compute(proxy)
            }
            .onChange(of: proxy.size) { oldValue, newValue in
                compute(proxy)
            }
        }
    }

    private func gradient() -> LinearGradient {
        var colors: [Color] = [color, color.darken(factor: 0.3)]
        if color.luminance() < 0.25 {
            colors = [color, color.lighten(factor: 0.3)]
        }
        return LinearGradient(colors: colors,
                              startPoint: .top,
                              endPoint: .bottom)
    }

    private func compute(_ proxy: GeometryProxy) {
        contentRadius = MapPinShape.radius(in: proxy.frame(in: .local)) * 0.85
        let circleCenter = MapPinShape.center(in: proxy.frame(in: .local))
        contentOffsetY = circleCenter.y - proxy.frame(in: .local).midY
        fontSize = contentRadius * 0.9
        iconColor = color.luminance() > 0.7 ? .init(rgba: "444444") : .white
    }
}


#Preview {
    let w: CGFloat = 390
    let h: CGFloat = 350
    VStack {
        HStack {
            MapPinView(color: .red,
                       icon: Icon(rawValue: "sf:mappin"))
                .frame(width: 200, height: 200)

            MapPinView(color: .blue)
            .frame(width: 200, height: 200)
        }

        HStack {
            MapPinView(color: .red)
                .frame(width: 200, height: 200)

            MapPinView(color: .blue,
                    icon: Icon(rawValue: "sf:mappin"))
            .frame(width: 200, height: 200)
        }
        
        HStack {
            MapPinView(color: Color(white: 1),
                    icon: Icon(rawValue: "sf:mappin"))
            .frame(width: 100, height: 100)
            MapPinView(color: Color(white: 0.8))
            .frame(width: 100, height: 100)
            MapPinView(color: Color(white: 0.6),
                    icon: Icon(rawValue: "sf:mappin"))
            .frame(width: 100, height: 100)
        }
        HStack {
            MapPinView(color: Color(white: 0.4))
            .frame(width: 100, height: 100)
            MapPinView(color: Color(white: 0.2),
                    icon: Icon(rawValue: "sf:mappin"))
            .frame(width: 100, height: 100)
            MapPinView(color: Color(white: 0))
            .frame(width: 100, height: 100)
        }
    }
}


