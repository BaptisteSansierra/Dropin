//
//  AuthIconBadge.swift
//  Dropin
//
//  Created by baptiste sansierra on 10/7/26.
//

import SwiftUI

struct AuthIconBadge: View {
    
    private var systemImage: String
    
    init(systemImage: String) {
        self.systemImage = systemImage
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.surface2)
            .stroke(.textPrimary)
            .frame(width: 64, height: 64)
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(.dropinPrimary)
            }
    }
}
