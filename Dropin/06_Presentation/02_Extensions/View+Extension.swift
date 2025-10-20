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
    
//    func toolbarPreference(_ items: [ToolbarPreferenceItem]) -> some View {
//        modifier(ToolbarPreference(items: items))
//    }
}
