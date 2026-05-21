//
//  FirstAppear.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/10/25.
//

import SwiftUI

struct FirstAppear: ViewModifier {

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
