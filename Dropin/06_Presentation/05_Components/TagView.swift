//
//  TagView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

/// SDTag UI representation: colored rounded rect text 
struct TagView: View {
    
    // MARK: - private vars
    private var name: String
    private var color: Color

    // MARK: - Body
    var body: some View {
        Text(name)
            .font(.footnote)
            .bold()
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .background(color)
            .cornerRadius(6)
    }

    // MARK: - init
    init(name: String, color: Color) {
        self.name = name
        self.color = color
    }
}

#Preview {
    TagView(name: "Restaurant", color: .dropinSecondary)
}
