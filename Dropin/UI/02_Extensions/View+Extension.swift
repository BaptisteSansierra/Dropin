//
//  View+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 30/7/25.
//

import SwiftUI

extension View {
    
    func onFirstAppear(_ action: @escaping () -> ()) -> some View {
        modifier(FirstAppear(action: action))
    }
}

private struct FirstAppear: ViewModifier {

    let action: () -> ()
    
    @State private var alreadyHappened = false
    
    func body(content: Content) -> some View {
        content.onAppear {
            guard !alreadyHappened else { return }
            alreadyHappened = true
            action()
        }
    }
}
