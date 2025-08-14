//
//  GroupView.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/8/25.
//

import SwiftUI

/// SDGroup UI representation: bordered rounded rect text
struct GroupView: View {
    
    // MARK: - private vars
    private var name: String
    private var color: Color
    private var hasDestructiveBt: Bool
    private var destructiveAction: (() -> Void)?

    // MARK: - Body
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
            IcoButton(systemImage: "multiply", icoSize: 10, icoColor: .red)
                .onTapGesture {
                    destructiveAction?()
                }
                .opacity(hasDestructiveBt ? 1 : 0)
        }
    }

    // MARK: - init
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
