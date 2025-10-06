//
//  GroupListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI
import SwiftData

struct GroupListView: View {
    
    // MARK: - State & Bindings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\SDGroup.name), SortDescriptor(\SDGroup.creationDate)]) private var groups: [SDGroup]
    @State private var showingRemoveAlert: Bool = false
    @State private var groupToRemove: SDGroup? = nil
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    NavigationLink(value: group) {
                        HStack {
                            GroupView(name: group.name, color: Color(rgba: group.color), hasDestructiveBt: false)
                            Spacer()
                            let nPlaces = group.places.count
                            Text("group_list_view.num_places_\(nPlaces)")
                        }
                        .swipeActions {
                            Button() {
                                deleteGroup(group)
                            } label: {
                                Label("common.delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
            .navigationTitle("common.groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DropinToolbar.Burger()
            }
            .navigationDestination(for: SDGroup.self) { group in
                GroupDetailsView(group: group)
            }
            .alert("alert.remove_group_title",
                   isPresented: $showingRemoveAlert,
                   presenting: groupToRemove) { group in
                
                Button("common.cancel", role: .cancel) {
                    groupToRemove = nil
                }
                Button("common.delete", role: .destructive) {
                    modelContext.delete(group)
                    groupToRemove = nil
                }
            } message: { group in
                if group.places.count > 0 {
                    Text("alert.remove_group_body_\(group.name)_\(group.places.count)")
                } else {
                    Text("alert.remove_group_empty_body_\(group.name)")
                }
            }
        }
    }

    // MARK: - Actions
    private func deleteGroup(_ group: SDGroup) {
        groupToRemove = group
        showingRemoveAlert = true
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
