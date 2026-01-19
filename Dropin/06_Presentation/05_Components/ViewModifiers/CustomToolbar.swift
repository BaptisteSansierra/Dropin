//
//  CustomToolbar.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/10/25.
//

import SwiftUI

#if true

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

#endif
