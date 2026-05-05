//
//  AlertOk.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/4/26.
//

import SwiftUI

struct AlertOk: ViewModifier {

    let isPresented: Binding<Bool>
    let title: LocalizedStringKey
    let body: LocalizedStringKey?
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if let body = body {
            content.alert(title,
                          isPresented: isPresented,
                          actions: ok) {
                Text(body)
            }
        } else {
            content.alert(title,
                          isPresented: isPresented,
                          actions: ok)
        }
    }
    
    private func ok() -> some View {
        Button("common.ok", role: .cancel, action: {
            action?()
        })
    }
}
