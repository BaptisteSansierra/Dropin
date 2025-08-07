//
//  MapIcoButton.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/25.
//

import SwiftUI

struct MapIcoButton: View {
    
    var systemImage: String
    var offset: CGPoint
    var imageFrame: CGSize
    var color: Color
    //var leftCaption: String?
    var rightCaption: String?

    var body: some View {
        HStack {
//            if let leftCaption = leftCaption {
//            }
            ZStack {
                Circle()
                    .fill(.white)
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
                    .font(.caption2)
                    .padding(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                    .background(.white)
                    .cornerRadius(5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(color, style: StrokeStyle(lineWidth: 0))
                    }
            }
        }
    }
    
    init(systemImage: String,
         offset: CGPoint = .zero,
         imageFrame: CGSize = CGSize(width: 20, height: 20),
//         leftCaption: String? = nil,
         rightCaption: String? = nil,
         color: Color = .dropinPrimary) {
        self.systemImage = systemImage
        self.offset = offset
        self.imageFrame = imageFrame
//        self.leftCaption = leftCaption
        self.rightCaption = rightCaption
        self.color = color
    }
}

#Preview {
    VStack {
        MapIcoButton(systemImage: "gear", imageFrame: CGSize(width: 15, height: 15))
        MapIcoButton(systemImage: "mappin", imageFrame: CGSize(width: 15, height: 15), rightCaption: "caption")
    }
    .background(.brown)
}
