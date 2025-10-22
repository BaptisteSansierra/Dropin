//
//  ToolbarContentPreference.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/10/25.
//

import SwiftUI

@MainActor
struct CustomToolbarContent: Equatable, Sendable {
    let id = UUID()
    let tabIndex: Int
    let leading: AnyView?
    let trailing: AnyView?
    let title: AnyView?
    
    nonisolated static func == (lhs: CustomToolbarContent, rhs: CustomToolbarContent) -> Bool {
        lhs.id == rhs.id
    }
}

struct ToolbarContentPreference: PreferenceKey {
    static let defaultValue: CustomToolbarContent? = nil
    
    static func reduce(value: inout CustomToolbarContent?, nextValue: () -> CustomToolbarContent?) {
        value = nextValue() ?? value
    }
}
