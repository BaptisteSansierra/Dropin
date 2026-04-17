//
//  PlaceIconView.swift
//  Dropin
//
//  Created by baptiste sansierra on 24/2/26.
//

import SwiftUI

struct PlaceIconView: View {
    
    var icon: Icon
    var shadow: Bool
    var size: CGFloat

    init(icon: Icon, shadow: Bool = true, size: CGFloat = 20) {
        self.icon = icon
        self.shadow = shadow
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.textPrimary)
                .frame(width: size, height: size)
                .if(shadow, action: { view in
                    view.shadow(color: .textPrimary.opacity(0.5),
                                radius: 3,
                                x: -2, y: 2)
                })
            Circle()
                .fill(.backgroundPrimary)
                .frame(width: size - 2, height: size - 2)
            IconView(icon: icon)
                .size(size * 10 / 20)
        }
    }
}

#Preview {
    
    VStack(spacing: 20) {
        HStack {
            PlaceIconView(icon: Icon(rawValue: "sf:tag")!)
            PlaceIconView(icon: Icon(rawValue: "fa:spa")!)
        }
        HStack {
            PlaceIconView(icon: Icon(rawValue: "sf:phone")!, shadow: false)
            PlaceIconView(icon: Icon(rawValue: "fa:pizza-slice")!, shadow: false)
        }
        HStack {
            PlaceIconView(icon: Icon(rawValue: "sf:globe")!, shadow: false, size: 35)
            PlaceIconView(icon: Icon(rawValue: "fa:ice-cream")!, shadow: false, size: 35)
        }
    }
}
