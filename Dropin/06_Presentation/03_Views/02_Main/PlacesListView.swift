//
//  PlacesListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI
import SwiftData

struct PlacesListView: View {
        
    // MARK: - State & Bindings
    @State private var viewModel: PlacesListViewModel
    @Binding private var places: [PlaceUI]

    // MARK: - Dependencies
    @Environment(NavigationContext.self) private var navigationContext

    // MARK: - Init
    init(viewModel: PlacesListViewModel, places: Binding<[PlaceUI]>) {
        self.viewModel = viewModel
        self._places = places
    }

    // MARK: - Body
    var body: some View {
        
        @Bindable var navigationContext = navigationContext
        
        List {
            // Show places without groups (empty if #2)
            if !viewModel.grouped { flatList }
            // Show grouped places (empty if #1)
            else { groupedList }
        }
        .listStyle(.grouped)
        //.searchable(text: $viewModel.searchText, isPresented: $navigationContext.searchBarPresented)
        .searchable(text: $viewModel.searchText)
        .searchPresentationToolbarBehavior(.avoidHidingContent)
        .task {
            try? await Task.sleep(nanoseconds: 1)

            Task {
                viewModel.updateSorting(places)
            }
        }
        // TO RESTORE
//            .onChange(of: places) {
//                viewModel.updateSorting(places)
//            }
        .refreshable {
            Task {
                try await self.viewModel.loadPlaces()
            }
        }
        .onChange(of: viewModel.grouped) {
            viewModel.updateSorting(places)
        }
        .onChange(of: viewModel.sortMode) {
            viewModel.updateSorting(places)
        }
        .customToolbar(tabIndex: 1,
                       leading: {
                           BurgerToolbarView()
                       }, trailing: {
                           trailingToolbarContent
                       }) {
                           LogoToolbarView()
                       }
    }

    // MARK: - Subviews
    private var trailingToolbarContent: some View {
        Group {
            Button("common.organize_by_group", systemImage: viewModel.grouped ? "rectangle.3.group.bubble" : "rectangle.3.group.bubble.fill") {
                viewModel.grouped.toggle()
            }
            .tint(.dropinPrimary)
            Menu("common.sort", systemImage: "arrow.up.arrow.down") {
                Picker("common.sort", selection: $viewModel.sortMode) {
                    Text("common.sort.by_distance")
                        .tag(PlacesListViewModel.SortMode.distance)
                    Text("common.sort.by_name")
                        .tag(PlacesListViewModel.SortMode.alphabetically)
                    Text("common.sort.by_creation_date")
                        .tag(PlacesListViewModel.SortMode.creationDate)
                }
                .pickerStyle(.inline)
            }
            .tint(.dropinPrimary)
        }
    }

    private var flatList: some View {
        ForEach(viewModel.sortedPlaces) { place in
            NavigationLink(value: PlaceMapper.toDomain(place)) {
                PlaceRowView(place: place)
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
            }
        }
    }

    private var groupedList: some View {
        Group {
            let keys: [String] = Array(viewModel.groupedSortedPlaces.keys)
            let sortedKeys = keys.sorted()
            ForEach(sortedKeys, id: \.self) { groupId in
                if let groupPlaces = viewModel.groupedSortedPlaces[groupId],
                   let firstPlace = groupPlaces.first,
                   let groupName = firstPlace.group?.name {
                    Section(groupName) {
                        ForEach(groupPlaces) { place in
                            NavigationLink(value: PlaceMapper.toDomain(place)) {
                                PlaceRowView(place: place)
                                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                            }
                        }
                    }
                }
            }
            if viewModel.ungroupedSortedPlaces.count > 0 {
                Section("common.not_grouped") {
                    ForEach(viewModel.ungroupedSortedPlaces) { place in
                        NavigationLink(value: PlaceMapper.toDomain(place)) {
                            PlaceRowView(place: place)
                                .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                        }
                    }
                }
            }
        }
    }
}


#if DEBUG
struct MockPlacesListView: View {
    var mock: MockContainer
    @State var places: [PlaceUI]

    var body: some View {
        mock.appContainer.createPlacesListView(places: $places)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.places = mock.getAllPlaceUI()
    }
}

#Preview {
    NavigationStack {
        TabView {
            MockPlacesListView()
                .environment(LocationManager())
                .environment(NavigationContext())
                .tabItem {
                    Label("common.map", systemImage: "map")
                }
            Text("EmptyTab")
                .tabItem {
                    Label("Emptyti", systemImage: "cross")
                }
        }
        .navigationTitle("Pipo")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#endif
