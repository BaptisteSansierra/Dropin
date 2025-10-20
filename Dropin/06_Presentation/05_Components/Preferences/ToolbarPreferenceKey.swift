//
//  ToolbarPreferenceKey.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/10/25.
//

import SwiftUI


@MainActor
struct CustomToolbarItem: Identifiable, Sendable {
    let id = UUID()
    //let icon: String
    //let action: @Sendable () -> Void
    let content: AnyView
}

@MainActor
struct CustomToolbarContent: Equatable, Sendable {
    let id = UUID()
    let leading: [CustomToolbarItem]
    let trailing: [CustomToolbarItem]
    let title: String
    let titleView: AnyView?
    
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


/*
struct ToolbarPreferenceItem: Identifiable, Equatable {
    var id = UUID()
    var placement: ToolbarItemPlacement
    var content: any View
    
    static func == (lhs: ToolbarPreferenceItem, rhs: ToolbarPreferenceItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct ToolbarPreferenceKey: PreferenceKey {
    
    //nonisolated(unsafe) static var defaultValue: [ToolbarPreferenceItem] = []
    static var defaultValue: [ToolbarPreferenceItem] { [] }
    
    static func reduce(value: inout [ToolbarPreferenceItem],
                       nextValue: () -> [ToolbarPreferenceItem]) {
        value.append(contentsOf: nextValue())
    }
    
    
//    
//    static var defaultValue: () -> [ToolbarPreferenceItem] { [ToolbarPreferenceItem]() }
//
//    static func reduce(value: inout [ToolbarPreferenceItem],
//                       nextValue: () -> [ToolbarPreferenceItem]) {
//        value.append(contentsOf: nextValue())
//    }
}
*/
