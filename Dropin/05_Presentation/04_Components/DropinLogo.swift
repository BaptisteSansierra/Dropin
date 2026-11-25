//
//  DropinLogo.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/8/25.
//

import SwiftUI

/// The logo: circle with circles
struct DropinLogo: View {
    
    enum Variant: String, CaseIterable {
        case logo
        case variant1
        case variant2
        case variant3
        case random
        
        static func random() -> Variant {
            allCases.randomElement()!
        }
        
        static func random(excluded: Variant) -> Variant {
            allCases
                .filter { $0 != excluded }
                .randomElement()!
        }
    }

    // MARK: - private vars
    private var lineWidthMuliplier: CGFloat = 1
    private var pinSizeMuliplier: CGFloat = 1
    private var variant: Variant

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            Circle()
                .stroke(.dropinPrimary,
                        lineWidth: diameter * 0.04 * lineWidthMuliplier)
                .frame(width: diameter, height: diameter)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .overlay {
                    displayContent(diameter * 0.5)
                }
        }
    }
    
    // MARK: - init
    init(variant: Variant = .logo,
         lineWidthMuliplier: CGFloat = 1,
         pinSizeMuliplier: CGFloat = 1) {
        self.variant = variant
        self.lineWidthMuliplier = lineWidthMuliplier
        self.pinSizeMuliplier = pinSizeMuliplier
    }
    
    @ViewBuilder
    private func displayContent(_ radius: CGFloat) -> some View {
        let (count, colors, angles, offsets) = getData()
        ForEach(0..<count, id: \.self) { idx in
            InCircle(color: colors[idx],
                     radius: radius * 0.14 * pinSizeMuliplier)
            .offset(x: cos(angles[idx]) * radius * offsets[idx],
                    y: sin(angles[idx]) * radius * offsets[idx])
        }
    }
        
    private func getData() -> (Int, [Color], [CGFloat], [CGFloat]) {
        var count: Int
        var colors: [Color]
        var angles: [CGFloat]
        var offsets: [CGFloat]
        switch variant {
            case .logo:
                count = 5
                colors = [.dropinSecondary, .info, .dropinSecondary, .dropinSecondary, .warning]
                angles = [CGFloat.pi * 0.60,
                            CGFloat.pi * 0.88,
                            CGFloat.pi * 1.79,
                            CGFloat.pi * 1.63,
                            CGFloat.pi * 1.8]
                offsets = [0.61, 0.53, 0.62, 0.55, 0.35]
            case .variant1:
                count = 5
                colors = [.warning, .info, .dropinSecondary, .dropinSecondary, .dropinSecondary]
                angles = [CGFloat.pi * 1.33,
                          CGFloat.pi * 1.7,
                          CGFloat.pi * 0.15,
                          CGFloat.pi * 0.41,
                          CGFloat.pi * 0.59]
                offsets = [0.65, 0.61, 0.50, 0.62, 0.59]
            case .variant2:
                count = 5
                colors = [.dropinSecondary, .dropinSecondary, .info, .warning, .dropinSecondary]
                angles = [CGFloat.pi * 0.5,
                          CGFloat.pi * 1.85,
                          CGFloat.pi * 1.74,
                          CGFloat.pi * 1.52,
                          CGFloat.pi * 1.29]
                offsets = [0.2, 0.61, 0.65, 0.75, 0.45]
            case .variant3:
                count = 5
                colors = [.dropinSecondary, .dropinSecondary, .warning, .dropinSecondary, .info]
                angles = [CGFloat.pi * 0.65,
                          CGFloat.pi * 0.33,
                          CGFloat.pi * 0.6,
                          CGFloat.pi * 1.4,
                          CGFloat.pi * 1.85]
                offsets = [0.2, 0.4, 0.65, 0.57, 0.53]
            case .random:
                count = Int.random(in: 3...6)
                colors = (0..<count).map { _ in [Color.dropinSecondary, Color.dropinSecondary, Color.info, Color.warning].randomElement()! }
                angles = (0..<count).map { _ in CGFloat.pi * CGFloat.random(in: 0...2) }
                offsets = (0..<count).map { _ in CGFloat.random(in: 0.5...0.85) }
        }
        return (count, colors, angles, offsets)
    }
}

fileprivate struct InCircle: View {
    
    // MARK: - private vars
    private var color: Color
    private var radius: CGFloat
    
    // MARK: - Body
    var body: some View {
        Circle()
            .foregroundStyle(color)
            .frame(width: radius, height: radius)
    }
    
    // MARK: - init
    init(color: Color, radius: CGFloat) {
        self.color = color
        self.radius = radius
    }
}

#Preview {
    VStack(alignment: .trailing) {
        DropinLogo(variant: .logo)
            .padding(5)
        Text("Logo")
        Divider()
        DropinLogo(variant: .variant1)
            .padding(5)
            .background(.textPrimary)
        Text("Variant1")
        Divider()
        DropinLogo(variant: .variant2)
            .padding(5)
        Text("Variant2")
        Divider()
        DropinLogo(variant: .variant3)
            .padding(5)
            .background(.textPrimary)
        Text("Variant3")
        Divider()
        DropinLogo(variant: .random)
            .padding(5)
        Text("Random")
        Divider()
    }
}
