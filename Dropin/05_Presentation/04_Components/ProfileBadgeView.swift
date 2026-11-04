//
//  ProfileBadgeView.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/6/26.
//

import SwiftUI


struct ProfileBadgeView: View {
    
    enum Style {
        case small
        case large
    }
    
    // MARK: properties
    private var initials: String
    private var style: Style
    private var bgColor: Color
    private var fgColor: Color
    private var stroke: Color
    private var gradient: LinearGradient {
        let gradient = Gradient(colors: [bgColor.opacity(1),
                                         .dropinSecondary.opacity(0.4)])
                                         //.shade5])
        return LinearGradient(gradient: gradient,
                              startPoint: .top,
                              endPoint: .bottomTrailing)
    }

    // MARK: init
    init(initials: String,
         style: Style,
         bgColor: Color = .dropinSecondary,
         fgColor: Color = .backgroundPrimary,
         stroke: Color = .clear) {
        self.initials = initials
        self.style = style
        self.bgColor = bgColor
        self.fgColor = fgColor
        self.stroke = stroke
    }
    
    // MARK: body
    var body: some View {
        Circle()
            .fill(gradient)
            .stroke(stroke, lineWidth: 0.1)
            .overlay {
                Text(initials)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .textStyle(style == .small ? .avatarSmall : .avatarLarge,
                               color: fgColor)
                    .padding(.horizontal, 3)
            }
            .frame(width: style == .small ? 53 : 90)
            .compositingGroup()
    }
}

#Preview {
    VStack {
        Spacer()
        ProfileBadgeView(initials: "JD", style: .large)
            .shadow(color: .blue, radius: 5, x: 2, y: 1)

        ProfileBadgeView(initials: "JD",
                         style: .large,
                         bgColor: .dropinPrimary,
                         stroke: .black)
        
        ProfileBadgeView(initials: "JD",
                         style: .large,
                         bgColor: .dropinPrimary,
                         stroke: .black)
        Spacer()
        ProfileBadgeView(initials: "JD", style: .small)
        Spacer()
    }
}
