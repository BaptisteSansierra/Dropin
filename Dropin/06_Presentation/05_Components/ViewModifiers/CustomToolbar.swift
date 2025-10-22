//
//  CustomToolbar.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/10/25.
//

import SwiftUI

struct CustomToolbar: ViewModifier {
    
    let tabIndex: Int
    let leading: AnyView?
    let trailing: AnyView?
    let title: AnyView?

    func body(content: Content) -> some View {
        content
            .preference(key: ToolbarContentPreference.self,
                        value: CustomToolbarContent(tabIndex: tabIndex,
                                                    leading: leading,
                                                    trailing: trailing,
                                                    title: title))
    }
}


//struct ToolbarPreference: ViewModifier {
//
//    let toolbarContent: CustomToolbarContent
//
//    func body(content: Content) -> some View {
//        content
//            .preference(key: ToolbarContentPreference.self,
//                        value: CustomToolbarContent(leading: toolbarContent.leading,
//                                                    trailing: toolbarContent.trailing,
//                                                    title: toolbarContent.title,
//                                                    titleView: toolbarContent.titleView))
//    }
//}
//
//
//extension View {
//    func customToolbar(title: String,
//                       titleView: AnyView? = nil,
//                       leading: [CustomToolbarItem] = [],
//                       trailing: [CustomToolbarItem] = []) -> some View {
//        self.preference(
//            key: ToolbarContentPreference.self,
//            value: CustomToolbarContent(leading: leading,
//                                        trailing: trailing,
//                                        title: title,
//                                        titleView: titleView)
//        )
//    }
//}
