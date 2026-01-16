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

    func customToolbar<Leading: View, Trailing: View, Title: View>(tabIndex: Int = 0,
                                                                   @ViewBuilder leading: () -> Leading = { EmptyView() },
                                                                   @ViewBuilder trailing: () -> Trailing = { EmptyView() },
                                                                   @ViewBuilder title: () -> Title = { EmptyView() } ) -> some View {
        let leadingView = leading()
        let trailingView = trailing()
        let titleView = title()

        return modifier(CustomToolbar(tabIndex: tabIndex,
                                      leading: leadingView is EmptyView ? nil : AnyView(leadingView),
                                      trailing: trailingView is EmptyView ? nil : AnyView(trailingView),
                                      title: titleView is EmptyView ? nil : AnyView(titleView)))
    }
}
