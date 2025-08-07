//
//  GroupView.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/8/25.
//

import SwiftUI

struct GroupView: View {
    
    var name: String
    var color: Color
    var hasDestructiveBt: Bool
    var destructiveAction: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .center) {
                Text(name)
                    .font(.headline)
                    .padding(9)
                    .cornerRadius(5)
                    .overlay {
                        RoundedRectangle(cornerSize: CGSize(width: 6, height: 6))
                            .stroke(color, lineWidth: 2)
                    }
                    .padding()
            }
            if hasDestructiveBt {
                IcoButton(systemImage: "multiply", icoSize: 10, icoColor: .red)
                    .onTapGesture {
                        destructiveAction?()
                    }
            }
        }
    }

    init(name: String, color: Color, hasDestructiveBt: Bool, destructiveAction: (() -> Void)? = nil) {
        self.name = name
        self.color = color
        self.hasDestructiveBt = hasDestructiveBt
        self.destructiveAction = destructiveAction
    }
}

#Preview {
    GroupView(name: "Cool", color: .brown, hasDestructiveBt: true)
}
