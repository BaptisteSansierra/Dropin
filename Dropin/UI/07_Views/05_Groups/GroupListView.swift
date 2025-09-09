//
//  GroupListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI
import SwiftData

struct GroupListView: View {
    
    @Query(sort: [SortDescriptor(\SDGroup.name), SortDescriptor(\SDGroup.creationDate)]) var groups: [SDGroup]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    Text("\(group.name)")
                }
            }
            .navigationTitle("common.groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DropinToolbar.Burger()
            }
        }
    }
}

#if DEBUG

private struct GLPreview: View {
    let container: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: SDPlace.self, configurations: config)
        } catch {
            fatalError("couldn't create model container")
        }
        for item in SDGroup.all {
            container.mainContext.insert(item)
        }
    }
    
    var body: some View {
        NavigationStack {
            GroupListView()
        }
        .modelContainer(container)
        .environment(LocationManager())
        .environment(NavigationContext())
    }
}

#Preview {
    GLPreview()
}
#endif
