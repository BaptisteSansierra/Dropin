//
//  PlacesListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI
import SwiftData

struct PlacesListView: View {
    
    enum SortMode: Int {
        case distance = 0
        case alphabetically = 1
        case creationDate = 2
    }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    @Environment(AppNavigationContext.self) private var navigationContext

    @Query private var places: [SDPlace]

    @State private var sortedPlaces: [SDPlace] = []
    @State private var groupedSortedPlaces: [SDGroup: [SDPlace]] = [:]
    @State private var ungroupedSortedPlaces: [SDPlace] = []
    @State private var searchText = ""
    @State private var grouped = false
    @State private var sortMode: SortMode = .distance
    
    var flatList: some View {
        ForEach(sortedPlaces) { place in
            NavigationLink(value: place) {
                PlaceItemListView(place: place)
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
            }
        }
    }

    var groupedList: some View {
        Group {
            ForEach(Array(groupedSortedPlaces.keys)) { group in
                Section(group.name) {
                    ForEach(groupedSortedPlaces[group]!) { place in
                        NavigationLink(value: place) {
                            PlaceItemListView(place: place)
                                .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                        }
                    }
                }
            }
            Section("Not grouped") {
                ForEach(ungroupedSortedPlaces) { place in
                    NavigationLink(value: place) {
                        PlaceItemListView(place: place)
                            .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // #1 Show places without groups (empty if #2)
                if !grouped {
                    flatList
                }
                    //.opacity(grouped ? 0 : 1)
                // #2 Show grouped places (empty if #1)
                else {
                    groupedList
                    //.opacity(grouped ? 1 : 0)
                }
            }
            .listStyle(.grouped)
            .onChange(of: places) {
                updateData()
            }
            .onChange(of: grouped) {
                updateData()
            }
            .onChange(of: sortMode) {
                updateData()
            }
            .onFirstAppear {
                updateData()
            }
            .searchable(text: $searchText)
            .toolbar {
                BurgerToolbar()
                LogoToolbar()
            }
            .toolbar {
                Button("Organize by group", systemImage: grouped ? "rectangle.3.group.bubble" : "rectangle.3.group.bubble.fill") {
                    grouped.toggle()
                }
                .tint(.dropinPrimary)

                Menu("Sort", systemImage: "arrow.up.arrow.down") {
                    Picker("Sort", selection: $sortMode) {
                        Text("By distance")
                            .tag(SortMode.distance)
                        Text("By name")
                            .tag(SortMode.alphabetically)
                        Text("By creation date")
                            .tag(SortMode.creationDate)
                    }
                    .pickerStyle(.inline)
                }
                .tint(.dropinPrimary)
            }
            .navigationDestination(for: SDPlace.self) { place in
                //navigationContext.editedPlace = place
                PlaceDetails()
                    .environment(place)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear() {
                //navigationContext.editedPlace = nil
            }
        }
    }
    
    init() {
        _places = Query(filter: #Predicate {
            if searchText.isEmpty {
                return true
            } else {
                return $0.name.localizedStandardContains(searchText)
            }
        }, sort: /*sorts*/ [])
    }
    
    private func updateData() {
        sortedPlaces.removeAll()
        groupedSortedPlaces.removeAll()
        ungroupedSortedPlaces.removeAll()
        guard grouped else {
            sortPlaces()
            return
        }
        sortGroupedPlaces()
    }

    private func sortGroupedPlaces() {
        groupedSortedPlaces.removeAll()
        ungroupedSortedPlaces.removeAll()
        for place in places {
            guard let group = place.group else {
                ungroupedSortedPlaces.append(place)
                continue
            }
            if groupedSortedPlaces[group] != nil {
                groupedSortedPlaces[group]?.append(place)
            } else {
                groupedSortedPlaces[group] = [place]
            }
        }
        // Sort all arrays
        ungroupedSortedPlaces = sortedPlaces(ungroupedSortedPlaces)
        let sortedKeys = groupedSortedPlaces.keys.sorted(using: SortDescriptor(\SDGroup.name))
        for k in sortedKeys {
            guard let groupPlaces = groupedSortedPlaces[k] else {
                groupedSortedPlaces.removeValue(forKey: k)
                continue
            }
            groupedSortedPlaces[k] = sortedPlaces(groupPlaces)
        }
    }
    
    private func sortPlaces() {
        sortedPlaces = sortedPlaces(places)
//        places.sorted { p1, p2 in
//            guard let d1 = locationManager.distanceTo(p1.coordinates),
//                  let d2 = locationManager.distanceTo(p2.coordinates) else {
//                if p1.name.compare(p2.name) == .orderedSame {
//                    return p1.creationDate.compare(p2.creationDate) == .orderedAscending
//                }
//                return p1.name.compare(p2.name) == .orderedAscending
//            }
//            return d1 < d2
//        }
    }
    
    private func sortedPlaces(_ places: [SDPlace]) -> [SDPlace] {
        switch sortMode {
            case .alphabetically:
                return places.sorted { p1, p2 in
                    if p1.name.compare(p2.name) == .orderedSame {
                        return p1.creationDate.compare(p2.creationDate) == .orderedAscending
                    }
                    return p1.name.compare(p2.name) == .orderedAscending
                }
            case .creationDate:
                return places.sorted { p1, p2 in
                    return p1.creationDate.compare(p2.creationDate) == .orderedAscending
                }
            case .distance:
                return places.sorted { p1, p2 in
                    guard let d1 = locationManager.distanceTo(p1.coordinates),
                          let d2 = locationManager.distanceTo(p2.coordinates) else {
                        if p1.name.compare(p2.name) == .orderedSame {
                            return p1.creationDate.compare(p2.creationDate) == .orderedAscending
                        }
                        return p1.name.compare(p2.name) == .orderedAscending
                    }
                    return d1 < d2
                }
        }
    }
    
//    private func deleteLocation(indexSet: IndexSet) {
//        guard indexSet.count <= 1 else {
//            assertionFailure("Cannot delete more than one loc at once")
//            return
//        }
//        guard let index = indexSet.first else { return }
//        placeToDelete = places[index]
//        showingDeleteWarning = true
//    }
}

#if DEBUG
private struct PLVPreview: View {
    let container: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: SDPlace.self, configurations: config)
        } catch {
            fatalError("couldn't create model container")
        }
        container.mainContext.insert(SDPlace.l1)
        container.mainContext.insert(SDPlace.l2)
        container.mainContext.insert(SDPlace.l3)
        container.mainContext.insert(SDPlace.l4)
    }
    
    var body: some View {
        NavigationStack {
            PlacesListView()
        }
        .modelContainer(container)
        .environment(LocationManager())
        .environment(AppNavigationContext())
    }
}

#Preview {
    PLVPreview()
}
#endif
//
//#Preview {
//    do {
//        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        let container = try ModelContainer(for: SDPlace.self, configurations: config)
//        container.mainContext.insert(SDPlace.locEx1)
//        container.mainContext.insert(SDPlace.locEx2)
//        LocationsListView()
//            .modelContainer(container)
//    } catch {
//        fatalError("couldn't create model container")
//    }
//
//}
