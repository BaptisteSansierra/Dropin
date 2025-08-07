//
//  DummyMain.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/8/25.
//

#if false

import SwiftUI

struct DummyMain: View {
    
    var body: some View {
        
        TabView {
            MainNavigationStack {
                List {
                    Section("AAAA") {
                        Text("qqqqq")
                        Text("wwwww")
                        Text("eeeee")
                        Text("rrrrr")
                        Text("ttttt")
                        Text("yyyyy")
                    }
                    Section("BBBB") {
                        Text("qqqqq")
                        Text("wwwww")
                        Text("eeeee")
                        Text("rrrrr")
                        Text("ttttt")
                        Text("yyyyy")
                    }
                }
                .navigationTitle("Menu")
                .navigationBarTitleDisplayMode(.inline)
                .listStyle(.grouped)
            }
                .tabItem {
                    Label("Menu", systemImage: "list.dash")
                }
            Text("User profile")
                .tabItem {
                    Label("Profile", systemImage: "square.and.pencil")
                }
        }

    }
}

#Preview {
    DummyMain()
        .environment(AppNavigationContext())
}

#endif
