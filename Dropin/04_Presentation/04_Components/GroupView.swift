//
//  GroupView.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/8/25.
//

import SwiftUI

/// SDGroup UI representation: bordered rounded rect text
struct GroupView: View {
    
    enum ActionType {
        case remove
        case edit
        case none
    }

    enum Size {
        case big
        case regular
        case small
    }

    // MARK: - private vars
    private var name: String
    private var color: Color
    private var border: Color
    private var c1: Color
    private var c2: Color
    private var c3: Color
    private var icon: Icon?
    private var action: (() -> Void)?
    private var actionType: ActionType
    private var size: Size
    
    private var style: TextStyleModifier.Style {
        switch size {
            case .big: .groupStickerBig
            case .regular: .groupSticker
            case .small: .groupStickerSmall
        }
    }
    private var textVerticalPadding: CGFloat {
        switch size {
            case .big: 10
            case .regular: 8.5
            case .small: 8
        }
    }
    private var textHorizontalPadding: CGFloat {
        switch size {
            case .big: 14
            case .regular: 11
            case .small: 8
        }
    }
    private var borderComponentWidth: CGFloat {
        switch size {
            case .big: 3
            case .regular: 2
            case .small: 1.5
        }
    }

    // MARK: - init
    init(name: String,
         color: Color,
         icon: Icon?,
         actionType: ActionType = .none,
         action: (() -> Void,)? = nil,
         size: Size = .regular) {
        self.name = name
        self.color = color
        self.icon = icon
        self.actionType = actionType
        self.action = action
        self.size = size
        
        (self.c1, self.c2, self.c3, self.border) = GroupView.computeColors(color)
    }
    
    init(group: GroupUI,
         actionType: ActionType = .none,
         action: (() -> Void)? = nil,
         size: Size = .regular) {
        self.name = group.name
        self.color = group.color
        self.icon = group.icon
        self.actionType = actionType
        self.action = action
        self.size = size

        (self.c1, self.c2, self.c3, self.border) = GroupView.computeColors(color)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: 10) {
                iconView
                Text(name)
                    .textStyle(style)
            }
            .padding(.vertical, textVerticalPadding)
            .padding(.horizontal, textHorizontalPadding)
            .background {
                RoundedRectangle(cornerSize: 8)
                    .fill(.clear)
                    .stroke(border, style: .init(lineWidth: 3.5))
            }
            .overlay {
                let lineW = borderComponentWidth
                ZStack {
                    GeometryReader { geom in
                        RoundedRectangle(cornerSize: 8)
                            .stroke(c1,
                                    style: StrokeStyle(lineWidth: lineW,
                                                       lineCap: .round,
                                                       lineJoin: .round
                                                      ))
                            .frame(width: geom.size.width,
                                   height: geom.size.height)
                        RoundedRectangle(cornerSize: 8)
                            .stroke(c2,
                                    style: StrokeStyle(lineWidth: lineW,
                                                       lineCap: .round,
                                                       lineJoin: .round
                                                      ))
                            .offset(x: 1, y: 1)
                            .frame(width: geom.size.width - 2,
                                   height: geom.size.height - 2)
                        RoundedRectangle(cornerSize: 8)
                            .stroke(c3,
                                    style: StrokeStyle(lineWidth: lineW,
                                                       lineCap: .round,
                                                       lineJoin: .round
                                                      ))
                            .offset(x: 2, y: 2)
                            .frame(width: geom.size.width - 4,
                                   height: geom.size.height - 4)
                    }
                }
            }
            actionButton
                .offset(x: 14, y: -14)
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        if let icon = icon {
            switch size {
                case .regular, .big:
                    IconView(icon: icon)
                        .sizeBody()
                        .fixedSize()
                        .frame(height: 10)
                case .small:
                    IconView(icon: icon)
                        .sizeCaption()
                        .fixedSize()
                        .frame(height: 10)
            }
        } else {
            Text("-")
                .foregroundStyle(.textPrimary)
                .font(.system(size: 30))
                .opacity(0.5)
                .fixedSize()
                .frame(height: 10)
                .offset(x: 3, y: -2)
        }
    }
    
    private var removeButton: some View {
        IcoButton(systemImage: "multiply",
                  icoSize: 10,
                  icoColor: .destructive,
                  action: { action?() })
    }
    
    private var editButton: some View {
        IcoButton(systemImage: "ellipsis",
                  icoSize: 10,
                  icoColor: .dropinPrimary,
                  action: { action?() })
    }
    
    private var actionButton: some View {
        Group {
            switch actionType {
                case .remove:
                    removeButton
                case .edit :
                    editButton
                default:
                    EmptyView()
            }
        }
    }
    
    static private func computeColors(_ base: Color) -> (Color, Color, Color, Color) {
        let c1 = base
        let c2 = base.opacity(0.5)
        let c3 = base.opacity(0.2)
        var border: Color = .clear
        if base.luminance() > 0.9 {
            border = Color(light: .textPrimary, dark: .clear)
        } else if base.luminance() < 0.1 {
            border = Color(light: .clear, dark: .textPrimary)
        }
        return (c1, c2, c3, border)
    }
}

#if DEBUG

struct MockGroupView: View {
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
        VStack(spacing: 0) {
            HStack {
                GroupView(name: "BIG", color: .green, icon: .sf("tag"), size: .big)
                GroupView(name: "RGL", color: .green, icon: .sf("tag"), size: .regular)
                GroupView(name: "SML", color: .green, icon: .sf("tag"), size: .small)
            }

            Divider()
                .padding(.vertical, 5)

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
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 20) {
            GroupView(name: "White", color: .white, icon: .sf("tag"))
            GroupView(name: "#DDDDDD", color: shade1, icon: .sf("tag"))
            GroupView(name: "#AAAAAA", color: shade2, icon: .sf("tag"))
            GroupView(name: "#999999", color: shade3, icon: .sf("tag"))
            GroupView(name: "#555555", color: shade4, icon: .sf("tag"))
            GroupView(name: "#222222", color: shade5, icon: .sf("tag"))
            GroupView(name: "Black", color: shade6, icon: .sf("tag"))
            Divider()
            
            GroupView(name: "Nice Group",
                      color: .brown,
                      icon: .sf("tag"))

            GroupView(name: "No Mark",
                      color: .brown,
                      icon: nil,
                      actionType: .remove,
                      action: { Log.info("Do the work") },
                      size: .small)

            GroupView(name: "Mark",
                      color: .brown,
                      icon: .sf("carrot"),
                      actionType: .edit,
                      action: { Log.info("Eat a carrot") },
                      size: .small)

            PlaceRectAnnotationView(color: .brown, icon: .sf("tag"))

        }
    }
}

#Preview {
    MockGroupView()
}

#endif

