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

    func taskOnce(_ action: @escaping () async -> ()) -> some View {
        modifier(TaskOnce(action: action))
    }
    
    func textStyle(_ style: TextStyleModifier.Style) -> some View {
        modifier(TextStyleModifier(style: style))
    }

    func outline(color: Color = .white, width: CGFloat = 0.5) -> some View {
        modifier(OutlineModifier(color: color, width: width))
    }
    
    func hideNavigationBarBelowIOS26() -> some View {
        modifier(HideNavigationBarBelowIOS26Modifier())
    }

    //    func `if`<Content: View>(_ condition: Bool, action: @escaping (Self)->Content ) -> some View {
    //        modifier(IfModifier(condition: condition, action: action))
    //    }
    
    func alertOk(isPresented: Binding<Bool>,
                 title: LocalizedStringKey,
                 body: LocalizedStringKey? = nil,
                 action: (() -> Void)? = nil) -> some View {
        modifier(AlertOk(isPresented: isPresented, title: title, body: body, action: action))
    }

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
    
    @ViewBuilder
    func ifBelowIOS26<Content: View>(action: (Self) -> Content, elseAction: ((Self) -> Content)? = nil) -> some View {
        if #available(iOS 26, *) {
            if let elseAction {
                elseAction(self)
            } else {
                self
            }
        } else {
            action(self)
        }
    }
}
