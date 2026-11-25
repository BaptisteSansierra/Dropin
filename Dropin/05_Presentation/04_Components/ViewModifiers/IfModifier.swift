//
//  IfModifier.swift
//  Dropin
//
//  Created by baptiste sansierra on 30/1/26.
//

import SwiftUI

struct IfModifier<Base: View, Result: View>: ViewModifier {

    let condition: Bool
    let action: (Base) -> Result
    
    func body(content: Content) -> some View {
        if condition, let base = content as? Base {
            action(base)
        } else {
            content
        }
    }
}
