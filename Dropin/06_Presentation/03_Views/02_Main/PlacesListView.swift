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
//    @State private var sortedPlaces: [SDPlace] = []
//    @State private var groupedSortedPlaces: [SDGroup: [SDPlace]] = [:]
//    @State private var ungroupedSortedPlaces: [SDPlace] = []
//    @State private var searchText = ""
//    @State private var grouped = false
//    @State private var sortMode: SortMode = .distance


    // MARK: - Init
    init(viewModel: PlacesListViewModel, places: Binding<[PlaceUI]>) {
        self.viewModel = viewModel
        self._places = places
    }

    // MARK: - Body
    var body: some View {
        
        List {
            // Show places without groups (empty if #2)
            if !viewModel.grouped { flatList }
            // Show grouped places (empty if #1)
            else { groupedList }
        }
        .listStyle(.grouped)
        .task {
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
        .searchable(text: $viewModel.searchText)
        
        .customToolbar(title: "",
                       titleView: AnyView(LogoToolbarView()),
                       leading: [CustomToolbarItem(content: AnyView(BurgerToolbarView()))],
                       trailing: [
                        CustomToolbarItem(content: AnyView(toolbarTrailingItem1)),
                        CustomToolbarItem(content: AnyView(toolbarTrailingItem2))
                       ])
        /*
        .toolbar {
            DropinToolbar.Burger()
            DropinToolbar.Logo()
        }
        .toolbar {
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
         */
    }

    // MARK: - Subviews

    private var toolbarTrailingItem1: some View {
        Button("common.organize_by_group", systemImage: viewModel.grouped ? "rectangle.3.group.bubble" : "rectangle.3.group.bubble.fill") {
            viewModel.grouped.toggle()
        }
        .tint(.dropinPrimary)
    }

    private var toolbarTrailingItem2: some View {
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
        }
    }
}

#endif


//#if DEBUG
//private struct PLVPreview: View {
//    let container: ModelContainer
//
//    init() {
//        do {
//            let config = ModelConfiguration(isStoredInMemoryOnly: true)
//            container = try ModelContainer(for: SDPlace.self, configurations: config)
//        } catch {
//            fatalError("couldn't create model container")
//        }
//        for l in SDPlace.all {
//            container.mainContext.insert(l)
//        }
//    }
//    
//    var body: some View {
//        NavigationStack {
//            PlacesListView()
//        }
//        .modelContainer(container)
//        .environment(LocationManager())
//        .environment(NavigationContext())
//    }
//}
//
//#Preview {
//    PLVPreview()
//}
//
//#endif
