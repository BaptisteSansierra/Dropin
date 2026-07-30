//
//  TagView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

/// SDTag UI representation: colored rounded rect text 
struct TagView: View {

    enum Style {
        case plain
        case selected
        case unselected
    }
    
    // MARK: - private vars
    private var name: String
    private var color: Color
    private var style: Style
    private var alphaBgColor: Color
    private var textColor: Color
    private let cornerRadius: CGFloat = 6

    // MARK: - init
    init(name: String, color: Color, style: Style = .plain) {
        self.name = name
        self.color = color
        let luminance = color.luminance()
        var lightColor: Color = .backgroundPrimary
        var darkColor: Color = .backgroundPrimary
        var lightAlphaBgColor: Color = .clear
        var darkAlphaBgColor: Color = .clear
        if luminance > 0.7 {
            let lerp = (luminance - 0.7) * 10 / 3
            //print("LUMI:\(luminance) +> LERP:\(lerp)")
            //lightColor = .lerp(from: lightColor, to: .init(rgba: "444444"), lerp)
            //lightColor = .lerp(from: .init(rgba: "444444"), to: lightColor, lerp)
            lightColor = .init(rgba: "444444")
            lightAlphaBgColor = .lerp(from: lightAlphaBgColor, to: .textPrimary, lerp)
        } else if luminance < 0.25 {
            let lerp = (0.25 - luminance) * 4
            print("LUMI:\(luminance) +> LERP:\(lerp)")
            darkColor = .lerp(from: darkColor, to: .init(rgba: "BBBBBB"), lerp)
            darkAlphaBgColor = .lerp(from: darkAlphaBgColor, to: .backgroundPrimaryL, lerp)
        }
        self.alphaBgColor = Color(light: lightAlphaBgColor, dark: darkAlphaBgColor)
        self.textColor = Color(light: lightColor, dark: darkColor)
        self.style = style
    }
    
    // MARK: - Body
    var body: some View {
        switch style {
            case .plain:
                plainTag
            case .selected:
                selectedTag
            case .unselected:
                unselectedTag
        }
    }

    private var plainTag: some View {
        Text(name)
            .foregroundStyle(textColor)
            .textStyle(.tagSticker)
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .background(color)
            .cornerRadius(cornerRadius)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(textColor, style: .init(lineWidth: 1))
            }
    }

    private var selectedTag: some View {
        HStack(spacing: 0) {
            Image(systemName: "checkmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(textColor)
                .frame(width: 10)
                .padding(.trailing, 6)
            Text(name)
                .textStyle(.tagSticker, color: textColor)
        }
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .background(color)
        .cornerRadius(cornerRadius)
        .background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(textColor, style: .init(lineWidth: 1))
        }

        /*
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 8, weight: .bold))
            Text(name)
                .textStyle(.tagSticker, color: textColor)
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color, in: Capsule())
         */
    }

    private var unselectedTag: some View {
        
        HStack(spacing: 0) {
            ZStack(alignment: .center) {
                Circle()
                    .fill(alphaBgColor)
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(color)
                    .frame(width: 7.5, height: 7.5)
            }
            .frame(width: 10)
            .padding(.trailing, 6)
            Text(name)
                .textStyle(.tagSticker, color: color)
                .outline(color: alphaBgColor.opacity(0.5), width: 0.1)
                //.shadow(color: alphaBgColor, radius: 1, x: 0, y: 0)
                //.padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                //.background {
                //    Capsule()
                //        .fill(alphaBgColor)
                //}
        }
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .cornerRadius(cornerRadius)
        .background {
            let shdOff: CGFloat = 0.25
            let shdCol = alphaBgColor.opacity(0.3)
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, style: .init(lineWidth: 1))
                .shadow(color: shdCol, radius: 0, x: shdOff, y: 0)
                .shadow(color: shdCol, radius: 0, x: -shdOff, y: 0)
                .shadow(color: shdCol, radius: 0, x: 0, y: shdOff)
                .shadow(color: shdCol, radius: 0, x: 0, y: -shdOff)
        }
    }
}

#if DEBUG

struct MockTagView: View {
    let shades: [(String, Color)] = [("WHITE", Color.white),
                                     ("EEE", Color(rgba: "#EEE")),
                                     ("DDD", Color(rgba: "#DDDDDD")),
                                     ("CCC", Color(rgba: "#CCC")),
                                     ("BBB", Color(rgba: "#BBB")),
                                     ("AAA", Color(rgba: "#AAAAAA")),
                                     ("999", Color(rgba: "#999999")),
                                     ("555", Color(rgba: "#555555")),
                                     ("444", Color(rgba: "#444")),
                                     ("333", Color(rgba: "#333")),
                                     ("222", Color(rgba: "#222222")),
                                     ("111", Color(rgba: "#111")),
                                     ("BLACK", Color.black)]
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
        TabView {
            plainView
                .tabItem {
                    Label {
                        Text("Plain")
                    } icon: {
                        Image(systemName: "capsule")
                    }
                    
                }
            selectorView
                .tabItem {
                    Label {
                        Text("Selector")
                    } icon: {
                        Image(systemName: "circle.grid.2x2.topleft.checkmark.filled")
                    }
                }
        }
    }
    
    private var plainView: some View {
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
    
    private var selectorView: some View {
        HStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(.backgroundPrimary)
                VStack {
                    selectorContent(style: .selected)
                    selectorContent(style: .unselected)
                }
            }
            .environment(\.colorScheme, .light)
            
            
            ZStack {
                Rectangle()
                    .fill(.backgroundPrimary)
                VStack {
                    selectorContent(style: .selected)
                    selectorContent(style: .unselected)
                }
            }
            .environment(\.colorScheme, .dark)
        }
    }
    
    private var content: some View {
        VStack {
            ForEach(shades, id: \.1.hashValue) { c in
                TagView(name: c.0, color: c.1, style: .selected)
            }
            Divider()
            ForEach(cols1, id: \.hashValue) { c in
                TagView(name: "Fixed", color: Color(rgba: c))
            }
            ForEach(cols2, id: \.hashValue) { c in
                TagView(name: "Random", color: c)
            }
        }
    }
    
    private func selectorContent(style: TagView.Style) -> some View {
        FlowLayout(alignment: .leading) {
            ForEach(shades, id: \.0) { c in
                TagView(name: c.0, color: c.1, style: style)
            }
            ForEach(cols1, id: \.hashValue) { c in
                TagView(name: "Fixed", color: Color(rgba: c), style: style)
            }
            ForEach(cols2, id: \.hashValue) { c in
                TagView(name: "Rdm", color: c, style: style)
            }
        }
        .padding(.leading, 5)
    }
}

#Preview {
    MockTagView()
}

#endif

