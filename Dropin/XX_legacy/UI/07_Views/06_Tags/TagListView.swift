//
//  TagListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI
import SwiftData

struct TagListView: View {

    // MARK: - State & Bindings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\SDTag.name), SortDescriptor(\SDTag.creationDate)]) private var tags: [SDTag]
    @State private var showingRemoveAlert: Bool = false
    @State private var tagToRemove: SDTag? = nil
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                ForEach(tags) { tag in
                    NavigationLink(value: tag) {
                        HStack {
                            TagView(name: tag.name, color: Color(rgba: tag.color))
                            Spacer()
                            let nPlaces = tag.places?.count ?? 0
                            Text("tag_list_view.num_places_\(nPlaces)")
                        }
                        .swipeActions {
                            Button() {
                                deleteTag(tag)
                            } label: {
                                Label("common.delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
            .navigationTitle("common.tags")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SDTag.self) { tag in
                TagDetailsView(tag: tag)
            }
            .toolbar {
                DropinToolbar.Burger()
            }
            .alert("alert.remove_tag_title",
                   isPresented: $showingRemoveAlert,
                   presenting: tagToRemove) { tag in
                
                Button("common.cancel", role: .cancel) {
                    tagToRemove = nil
                }
                Button("common.delete", role: .destructive) {
                    modelContext.delete(tag)
                    tagToRemove = nil
                }
            } message: { tag in
                if let places = tag.places, places.count > 0 {
                    Text("alert.remove_tag_body_\(tag.name)_\(places.count)")
                } else {
                    Text("alert.remove_tag_empty_body_\(tag.name)")
                }
            }
        }
    }

    // MARK: - Actions
    private func deleteTag(_ tag: SDTag) {
        tagToRemove = tag
        showingRemoveAlert = true
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
        container.mainContext.insert(SDTag.t9)
        container.mainContext.insert(SDTag.t11)
        container.mainContext.insert(SDTag.t14)
        container.mainContext.insert(SDPlace.l1)
        container.mainContext.insert(SDPlace.l2)

//        for item in SDPlace.all {
//            container.mainContext.insert(item)
//        }
//        for item in SDTag.all {
//            container.mainContext.insert(item)
//        }
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
