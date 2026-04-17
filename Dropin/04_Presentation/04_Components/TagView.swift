//
//  TagView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

/// SDTag UI representation: colored rounded rect text 
struct TagView: View {

    // MARK: - State

    // MARK: - private vars
    private var name: String
    private var color: Color
    private var gColor1: Color
    private var gColor2: Color
    private var textColor: Color
    private let cornerRadius: CGFloat = 6

    // MARK: - Body
    var body: some View {
        ZStack {
            Text(name)
                .foregroundStyle(textColor)
                .textStyle(.tagSticker)
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .background(color)
            //            .background(LinearGradient(colors: [gColor1, gColor2],
            //                                       startPoint: .topLeading,
            //                                       endPoint: .bottomTrailing))
                .cornerRadius(cornerRadius)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(textColor, style: .init(lineWidth: 1))
                }
        }
    }

    // MARK: - init
    init(name: String, color: Color) {
        self.name = name
        self.color = color
        let lightColor: Color = color.luminance() > 0.7 ? .init(rgba: "444444") : .backgroundPrimary
        let darkColor: Color = color.luminance() < 0.25 ? .init(rgba: "BBBBBB") : .backgroundPrimary
        self.textColor = Color(light: lightColor, dark: darkColor)
        
        gColor1 = color
        gColor2 = color.darken(factor: 0.1)
        if color.luminance() < 0.25 {
            gColor1 = color
            gColor2 = color.lighten(factor: 0.1)
        }
    }
}

#if DEBUG

struct MockTagView: View {
    let shade0 = Color.white
    let shade1 = Color(rgba: "#DDDDDD")
    let shade2 = Color(rgba: "#AAAAAA")
    let shade3 = Color(rgba: "#999999")
    let shade4 = Color(rgba: "#555555")
    let shade5 = Color(rgba: "#222222")
    let shade6 = Color.black
    let cols1 = ["#d8fff4",
                 "#f7ffea",
                 "#ffd6a9",
                 "#6a0959",
                 "#005c00"]
    var cols2: [Color] = []

    init() {
        cols2.append(Color.random())
        cols2.append(Color.random())
        cols2.append(Color.random())
        cols2.append(Color.random())
        cols2.append(Color.random())
    }

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(.backgroundPrimary)
                content
            }
            .environment(\.colorScheme, .light)
            ZStack {
                Rectangle()
                    .fill(.backgroundPrimary)
                content
            }
            .environment(\.colorScheme, .dark)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack {
            TagView(name: "White", color: shade0)
            TagView(name: "#DDDDDD", color: shade1)
            TagView(name: "#AAAAAA", color: shade2)
            TagView(name: "#999999", color: shade3)
            TagView(name: "#555555", color: shade4)
            TagView(name: "#222222", color: shade5)
            TagView(name: "Black", color: shade6)
            Divider()
            ForEach(cols1, id: \.hashValue) { c in
                TagView(name: "Fixed", color: Color(rgba: c))
            }
            ForEach(cols2, id: \.hashValue) { c in
                TagView(name: "Random", color: c)
            }
        }
    }
}

#Preview {
    MockTagView()
}

#endif

