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
        modifier(TextStyleModifier(style: style))
    }
    
    //    func `if`<Content: View>(_ condition: Bool, action: @escaping (Self)->Content ) -> some View {
    //        modifier(IfModifier(condition: condition, action: action))
    //    }
    
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, action: (Self) -> Content, elseAction: ((Self) -> Content)? = nil) -> some View {
        if condition {
            action(self)
        } else {
            if let elseAction {
                elseAction(self)
            } else {
                self
            }
        }
    }
    
    @ViewBuilder
    func ifShape<Content: Shape>(_ condition: Bool, action: (Self) -> Content, elseAction: ((Self) -> Content)? = nil) -> some View {
        if condition {
            action(self)
        } else {
            if let elseAction {
                elseAction(self)
            } else {
                self
            }
        }
    }
}
