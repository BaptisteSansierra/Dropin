//
//  DropinToolbar.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/8/25.
//

import SwiftUI

struct LogoToolbarView: View {
    
    @State private var logoVariant: DropinLogo.Variant = .logo
    
    var body: some View {
        HStack {
            Text("_NOTTR_Dr")
                .font(.titleBold)
                .foregroundStyle(.textPrimary)
                .padding(0)
                .offset(x: 4, y: 0)
            DropinLogo(variant: logoVariant,
                       lineWidthMuliplier: 2,
                       pinSizeMuliplier: 1.5)
                .frame(width: 25, height: 25)
            Text("_NOTTR_pin")
                .font(.titleBold)
                .foregroundStyle(.textPrimary)
                .padding(0)
                .offset(x: -4, y: 0)
        }
        .onTapGesture {
            logoVariant = DropinLogo.Variant.random(excluded: logoVariant)
        }
    }
}

struct BurgerToolbarView: View {
    
    @Binding private var showingSideMenu: Bool

    var body: some View {
        Button("", systemImage: "line.3.horizontal") {
            showingSideMenu.toggle()
        }
        .tint(.dropinPrimary)
    }
    
    init(showingSideMenu: Binding<Bool>) {
        self._showingSideMenu = showingSideMenu
    }
}

struct AddPlaceToolbarView: View {
    @Binding private var showingCreatePlaceMenu: Bool
    
    var body: some View {
        HStack {
            Button("", systemImage: "plus") {
                showingCreatePlaceMenu.toggle()
            }
            .tint(.dropinPrimary)
        }
    }
    
    init(showingCreatePlaceMenu: Binding<Bool>) {
        self._showingCreatePlaceMenu = showingCreatePlaceMenu
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
        @Binding private var showingSideMenu: Bool

        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading) {
                BurgerToolbarView(showingSideMenu: $showingSideMenu)
            }
        }
        
        init(showingSideMenu: Binding<Bool>) {
            self._showingSideMenu = showingSideMenu
        }
    }
    
    /// Right (+) button, toggling add place options
    struct AddPlace: ToolbarContent {
        @Binding private var showingCreatePlaceMenu: Bool

        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing) {
                AddPlaceToolbarView(showingCreatePlaceMenu: $showingCreatePlaceMenu)
            }
        }
        
        init(showingCreatePlaceMenu: Binding<Bool>) {
            self._showingCreatePlaceMenu = showingCreatePlaceMenu
        }
    }
}


#Preview {
    @Previewable @State var showingSideMenu: Bool = false
    @Previewable @State var showingCreatePlaceMenu: Bool = false
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
            DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
            DropinToolbar.AddPlace(showingCreatePlaceMenu: $showingCreatePlaceMenu)
        }
    }
}
