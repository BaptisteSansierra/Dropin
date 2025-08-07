//
//  TagView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

struct TagView: View {
    
    var name: String
    var color: Color

    var body: some View {
        Text(name)
            .font(.footnote)
            .bold()
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .background(color)
            .cornerRadius(6)
    }

    init(name: String, color: Color) {
        self.name = name
        self.color = color
    }
}

#Preview {
    TagView(name: "Restaurant", color: .dropinSecondary)
}
