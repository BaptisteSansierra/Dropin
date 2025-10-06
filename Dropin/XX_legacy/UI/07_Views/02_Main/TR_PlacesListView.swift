//
//  PlacesListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//
#if false

import SwiftUI
import SwiftData

struct PlacesListView: View {
    
    private enum SortMode: Int {
        case distance = 0
        case alphabetically = 1
        case creationDate = 2
    }
    
    // MARK: - State & Bindings
    @State private var sortedPlaces: [SDPlace] = []
    @State private var groupedSortedPlaces: [SDGroup: [SDPlace]] = [:]
    @State private var ungroupedSortedPlaces: [SDPlace] = []
    @State private var searchText = ""
    @State private var grouped = false
    @State private var sortMode: SortMode = .distance
    @Query private var places: [SDPlace]

    // MARK: - Dependencies
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    @Environment(NavigationContext.self) private var navigationContext

    // MARK: - Body
    var body: some View {
        
        @Bindable var navigationContext = navigationContext
        
        NavigationStack(path: $navigationContext.navigationPath) {
            List {
                // Show places without groups (empty if #2)
                if !grouped { flatList }
                // Show grouped places (empty if #1)
                else { groupedList }
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
                DropinToolbar.Burger()
                DropinToolbar.Logo()
            }
            .toolbar {
                Button("common.organize_by_group", systemImage: grouped ? "rectangle.3.group.bubble" : "rectangle.3.group.bubble.fill") {
                    grouped.toggle()
                }
                .tint(.dropinPrimary)

                Menu("common.sort", systemImage: "arrow.up.arrow.down") {
                    Picker("common.sort", selection: $sortMode) {
                        Text("common.sort.by_distance")
                            .tag(SortMode.distance)
                        Text("common.sort.by_name")
                            .tag(SortMode.alphabetically)
                        Text("common.sort.by_creation_date")
                            .tag(SortMode.creationDate)
                    }
                    .pickerStyle(.inline)
                }
                .tint(.dropinPrimary)
            }
            .navigationDestination(for: SDPlace.self) { place in
                PlaceDetailsView(place: Place(sdPlace: place))
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews
    private var flatList: some View {
        ForEach(sortedPlaces) { place in
            NavigationLink(value: place) {
                PlaceRowView(place: place)
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
            }
        }
    }

    private var groupedList: some View {
        Group {
            let sortedKeys = groupedSortedPlaces.keys.sorted(using: SortDescriptor(\SDGroup.name))
            ForEach(Array(sortedKeys)) { group in
                Section(group.name) {
                    ForEach(groupedSortedPlaces[group]!) { place in
                        NavigationLink(value: place) {
                            PlaceRowView(place: place)
                                .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                        }
                    }
                }
            }
            Section("common.not_grouped") {
                ForEach(ungroupedSortedPlaces) { place in
                    NavigationLink(value: place) {
                        PlaceRowView(place: place)
                            .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    }
                }
            }
        }
    }

    // MARK: - init
    init() {
        _places = Query(filter: #Predicate {
            if searchText.isEmpty {
                return true
            } else {
                return $0.name.localizedStandardContains(searchText)
            }
        }, sort: [])
    }
    
    // MARK: - private funcs
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
        for l in SDPlace.all {
            container.mainContext.insert(l)
        }
    }
    
    var body: some View {
        NavigationStack {
            PlacesListView()
        }
        .modelContainer(container)
        .environment(LocationManager())
        .environment(NavigationContext())
    }
}

#Preview {
    PLVPreview()
}
#endif
#endif
