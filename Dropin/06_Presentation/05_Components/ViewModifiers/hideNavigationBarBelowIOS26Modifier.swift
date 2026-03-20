//
//  hideNavigationBarBelowIOS26Modifier.swift
//  Dropin
//
//  Created by baptiste sansierra on 20/3/26.
//

import SwiftUI

struct HideNavigationBarBelowIOS26Modifier: ViewModifier {
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            content
                .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}
