//
//  DropinToolbar.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/8/25.
//

import SwiftUI

struct LogoToolbarView: View {
    var body: some View {
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

struct BurgerToolbarView: View {
    @Environment(NavigationContext.self) var navigationContext
    var body: some View {
        Button("", systemImage: "line.3.horizontal") {
            navigationContext.showingSideMenu.toggle()
        }
        .tint(.dropinPrimary)
    }
}

struct AddPlaceToolbarView: View {
    @Environment(NavigationContext.self) var navigationContext
    var body: some View {
        HStack {
            Button("", systemImage: "plus") {
                navigationContext.showingCreatePlaceMenu.toggle()
            }
            .tint(.dropinPrimary)
        }
    }
}


/// DropinToolbar contains toolbar items shared over the app
struct DropinToolbar {
    
    /// Centered dropin logo
    struct Logo: ToolbarContent {
        var body: some ToolbarContent {
            ToolbarItem(placement: .principal) {
                LogoToolbarView()
            }
        }
    }
    
    /// Left burger button, toggling sidebar
    struct Burger: ToolbarContent {
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading) {
                BurgerToolbarView()
            }
        }
    }
    
    /// Right (+) button, toggling add place options
    struct AddPlace: ToolbarContent {
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing) {
                AddPlaceToolbarView()
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
