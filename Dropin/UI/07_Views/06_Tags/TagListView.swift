//
//  TagListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI
import SwiftData

struct TagListView: View {
    
    @Query(sort: [SortDescriptor(\SDTag.name), SortDescriptor(\SDTag.creationDate)]) var tags: [SDTag]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(tags) { tag in
                    Text("\(tag.name)")
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DropinToolbar.Burger()
            }
        }
    }
}

#if DEBUG

private struct TLPreview: View {
    let container: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: SDPlace.self, configurations: config)
        } catch {
            fatalError("couldn't create model container")
        }
        for item in SDTag.all {
            container.mainContext.insert(item)
        }
    }
    
    var body: some View {
        NavigationStack {
            TagListView()
        }
        .modelContainer(container)
        .environment(LocationManager())
        .environment(NavigationContext())
    }
}


#Preview {
    TLPreview()
}
#endif
