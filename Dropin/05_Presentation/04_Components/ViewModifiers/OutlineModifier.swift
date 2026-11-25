//
//  OutlineModifier.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/3/26.
//

import SwiftUI

struct OutlineModifier: ViewModifier {
    
    var color: Color
    var width: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: 0, x: -width, y: -width)
            .shadow(color: color, radius: 0, x: width, y: -width)
            .shadow(color: color, radius: 0, x: -width, y: width)
            .shadow(color: color, radius: 0, x: width, y: width)
            .shadow(color: color, radius: 0, x: 0, y: -width)
            .shadow(color: color, radius: 0, x: 0, y: width)
            .shadow(color: color, radius: 0, x: -width, y: 0)
            .shadow(color: color, radius: 0, x: width, y: 0)
    }
}
