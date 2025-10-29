//
//  View+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 30/7/25.
//

import SwiftUI
import MapKit

extension View {
    
    // Allow assert to be called within a map content builder
    func assertionInMapContentBuilder(_ message: String) -> EmptyMapContent {
        assertionFailure(message)
        return EmptyMapContent()
    }

    // Allow assert to be called within a view builder
    func assertionInViewBuilder(_ message: String) -> EmptyView {
        assertionFailure(message)
        return EmptyView()
    }

    // Using ViewModifier FirstAppear
    func onFirstAppear(_ action: @escaping () -> ()) -> some View {
        modifier(FirstAppear(action: action))
    }
    
    // Using ViewModifier CustomToolbar
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
