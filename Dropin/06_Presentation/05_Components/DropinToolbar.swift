//
//  DropinToolbar.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/8/25.
//

import SwiftUI

/// DropinToolbar contains toolbar items shared over the app
struct DropinToolbar {
    
    /// Centered dropin logo
    struct Logo: ToolbarContent {
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("_NOTTR_Dr")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(0)
                        .offset(x: 4, y: 0)
                    DropinLogo(lineWidthMuliplier: 4, pinSizeMuliplier: 1.5)
                        .frame(width: 25, height: 25)
                    Text("_NOTTR_pin")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(0)
                        .offset(x: -4, y: 0)
                }
            }
        }
    }
    
    /// Left burger button, toggling sidebar
    struct Burger: ToolbarContent {
        
        @Environment(NavigationContext.self) var navigationContext
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading) {
                Button("", systemImage: "line.3.horizontal") {
                    navigationContext.showingSideMenu.toggle()
                }
                .tint(.dropinPrimary)
            }
        }
    }
    
    /// Right (+) button, toggling add place options
    struct AddPlace: ToolbarContent {
        
        @Environment(NavigationContext.self) var navigationContext
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button("", systemImage: "plus") {
                        navigationContext.showingCreatePlaceMenu.toggle()
                    }
                    .tint(.dropinPrimary)
                }
            }
        }
    }
}


#Preview {
    NavigationStack {
        VStack {
            Text("111")
            Text("222")
            Text("333")
        }
        .toolbar {
            DropinToolbar.Logo()
        }
        .toolbar {
            DropinToolbar.Burger()
            DropinToolbar.AddPlace()
        }
    }
    .environment(NavigationContext())
}
