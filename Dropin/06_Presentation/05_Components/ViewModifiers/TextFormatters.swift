//
//  TextFormater.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/12/25.
//

import SwiftUI

struct CellTitleFormater: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .fontWeight(.medium)
            .foregroundStyle(.black)
    }
}
struct CellSubtitleFormater: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundStyle(.gray)
    }
}

