//
//  TaskOnce.swift
//  Dropin
//
//  Created by baptiste sansierra on 8/6/26.
//

import SwiftUI

struct TaskOnce: ViewModifier {
    
    let action: () async -> Void
    
    @State private var executed: Bool = false
    
    func body(content: Content) -> some View {
        content.task {
            guard !executed else { return }
            executed = true
            await action()
        }
    }
}
