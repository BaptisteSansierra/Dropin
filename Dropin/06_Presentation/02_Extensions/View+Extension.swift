//
//  View+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 30/7/25.
//

import SwiftUI

extension View {
    
    // Using ViewModifier FirstAppear
    func onFirstAppear(_ action: @escaping () -> ()) -> some View {
        modifier(FirstAppear(action: action))
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

                        
//        let item = CustomToolbarContent(leading: leadingView is EmptyView ? nil : AnyView(leadingView),
//                                        trailing: trailingView is EmptyView ? nil : AnyView(trailingView),
//                                        title: titleView is EmptyView ? nil : AnyView(titleView))
//        return self.preference(key: ToolbarContentPreference.self,
//                               value: item)
        
    }
}
