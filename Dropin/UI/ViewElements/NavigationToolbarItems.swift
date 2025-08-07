//
//  NavigationToolbarItems.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/8/25.
//

import SwiftUI

struct LogoToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack {
                Text("Dr")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(0)
                    .offset(x: 4, y: 0)
                DropinLogo(lineWidthMuliplier: 4, pinSizeMuliplier: 1.5)
                    .frame(width: 25, height: 25)
                Text("pin")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(0)
                    .offset(x: -4, y: 0)
            }
        }
    }
}

struct BurgerToolbar: ToolbarContent {

    @Environment(AppNavigationContext.self) var appNavigationContext

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Menu", systemImage: "line.3.horizontal") {
                appNavigationContext.showingSideMenu.toggle()
            }
            .tint(.dropinPrimary)
        }
    }
}

struct AddPlaceToolbar: ToolbarContent {

    @Environment(AppNavigationContext.self) var appNavigationContext

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack {
                Button("Add", systemImage: "plus") {
                    appNavigationContext.showingCreatePlaceMenu.toggle()
                }
                .tint(.dropinPrimary)
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
            LogoToolbar()
        }
        .toolbar {
            BurgerToolbar()
        }
    }
    .environment(AppNavigationContext())
}
