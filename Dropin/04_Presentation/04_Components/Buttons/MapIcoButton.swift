//
//  MapIcoButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/25.
//

import SwiftUI

/// A button designed for map overlay
struct MapIcoButton: View {
    
    // MARK: - private vars
    private var systemImage: String
    private var offset: CGPoint
    private var imageFrame: CGSize
    private var color: Color
    private var rightCaption: String?
    private let action: () -> Void

    // MARK: - init
    init(systemImage: String,
         offset: CGPoint = .zero,
         imageFrame: CGSize = CGSize(width: 20, height: 20),
         rightCaption: String? = nil,
         color: Color = .dropinPrimary,
         action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.offset = offset
        self.imageFrame = imageFrame
        self.rightCaption = rightCaption
        self.color = color
        self.action = action
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: action, label: {
            content
        })
    }
    
    private var content: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(.backgroundPrimary)
                    .stroke(color, style: StrokeStyle(lineWidth: 1))
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(color)
                    .frame(width: imageFrame.width, height: imageFrame.height)
                    .offset(x: offset.x, y: offset.y)
            }
            .frame(width: 30, height: 30)
            if let rightCaption = rightCaption {
                Text(rightCaption)
                    .textStyle(.caption2)
                    .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                    .background(.backgroundPrimary)
                    .cornerRadius(5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(color, style: StrokeStyle(lineWidth: 0))
                    }
            }
        }
    }
}

#Preview {
    VStack {
        MapIcoButton(systemImage: "gear", imageFrame: CGSize(width: 15, height: 15)) {
            Log.debug("gear")
        }
        MapIcoButton(systemImage: "mappin", imageFrame: CGSize(width: 15, height: 15), rightCaption: "caption") {
            Log.debug("mappin")
        }
    }
    .background(.brown)
}
