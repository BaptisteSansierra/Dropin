//
//  View+Modifiers.swift
//  Dropin
//
//  Created by baptiste sansierra on 30/7/25.
//

import SwiftUI
import MapKit

// Apply modifiers
extension View {
    
    func onFirstAppear(_ action: @escaping () -> ()) -> some View {
        modifier(FirstAppear(action: action))
    }
    
    func textStyle(_ style: TextStyleModifier.Style) -> some View {
        self.modifier(TextStyleModifier(style: style))
    }
}
