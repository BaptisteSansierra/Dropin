//
//  PlacesListView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI

struct PlacesListView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: PlacesListViewModel
    @Binding private var selectedPlaceId: UUID?
    @Binding private var filter: PlaceFilter?
    @Environment(RootView.ActionBus.self) private var actionBus
    @Environment(AppSettings.self) private var appSettings

    // MARK: - Properties
    private var places: [PlaceUIModel]
    private var allPlacesCount: Int
    private var activePlaces: [PlaceUIModel] {
        places.filter { $0.isActive }
    }

    // MARK: - Init
    init(viewModel: PlacesListViewModel,
         places: [PlaceUIModel],
         allPlacesCount: Int,
         selectedPlaceId: Binding<UUID?>,
         filter: Binding<PlaceFilter?>) {
        self.viewModel = viewModel
        self.places = places
        self.allPlacesCount = allPlacesCount
        self._selectedPlaceId = selectedPlaceId
        self._filter = filter
    }
    
    // MARK: - Body
    var body: some View {
        if activePlaces.isEmpty {
            placeholderView
        } else {
            contentView
        }
    }
    
    // MARK: - Subviews
    private var contentView: some View {
        VStack(spacing: 0) {

            let searchedPlaces = viewModel.searchedPlaces(places)

            headerView(searchedPlaces.count)
                .padding(.top, 10)
            
            if searchedPlaces.count > 0 {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(searchedPlaces) { place in
                            placeRowView(place)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            } else {
                VStack {
                    searchPlaceholderView
                    Rectangle()
                        .fill(.backgroundPrimary)
                        .frame(height: 200)
                }
            }
        }
        .background(.backgroundPrimary)
        .safeAreaPadding(.bottom, DropinApp.ui.mainTabBarHeight)
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func headerView(_ searchedPlacesCount: Int) -> some View {
        VStack(spacing: 0) {
            let placeholder = "place_list.search.placeholder".localized()
            SearchTextFieldView(text: $viewModel.searchText,
                                placeholder: placeholder,
                                fillColor: .backgroundSecondary)
                .padding(.horizontal)
                .padding(.bottom)
            HStack {
                if let filter = filter {
                    filterView(filter)
                        .padding(.bottom)
                }
                Spacer()
            }
            .padding(.horizontal)
            Rectangle()
                .fill(.hairline)
                .frame(maxWidth: .infinity)
                .frame(height: 1)
            
            listHeaderView(searchedPlacesCount)
                .padding(.horizontal)
        }
        .padding(.bottom, 5)
    }

    private func filterView(_ filter: PlaceFilter) -> some View {
        HStack(spacing: 0) {
            Image(systemName: "line.3.horizontal.decrease")
                .padding(.trailing, 5)
            Text(filter.filterCount, format: .number)
            Text(String(" "))
            if filter.filterCount > 1 {
                Text("common.filters")
                    .padding(.trailing, 5)
            } else {
                Text("common.filter")
                    .padding(.trailing, 5)
            }
            Image(systemName: "multiply")
        }
        .textStyle(.footnote, color: .dropinPrimary)
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background {
            Capsule()
                .fill(.dropinPrimary.opacity(0.15))
                .stroke(.dropinPrimary)
        }
        .onTapGesture {
            self.filter = nil
        }
    }
    
    private func listHeaderView(_ searchedPlacesCount: Int) -> some View {
        ZStack {
            if searchedPlacesCount > 0 {
                countView(searchedPlacesCount)
                    .padding(.top)
            }
            syncingView
                .animation(.easeInOut(duration: 0.3), value: viewModel.syncStatus.isSyncing)
                .padding(.leading)
        }
    }

    private func countView(_ searchedPlacesCount: Int) -> some View {
        HStack(spacing: 0) {
            if filter != nil || !viewModel.searchText.isTrimmedEmpty {
                Text("common.subtotal_over_total_places_\(searchedPlacesCount)_\(allPlacesCount)")
            } else {
                Text(activePlaces.count, format: .number)
                Text(" ")
                if activePlaces.count > 1 {
                    Text("common.places")
                        .textCase(.lowercase)
                } else {
                    Text("common.place")
                        .textCase(.lowercase)
                }
            }
            Spacer()
        }
        .textStyle(.footnote, color: .textSecondary)
    }

    private var syncingView: some View {
        HStack {
            Spacer()
            Text("main.syncing")
                .textStyle(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .phaseAnimator([0.15, 0.5]) { view, opacity in
                    view.opacity(opacity)
                } animation: { _ in
                        .linear(duration: 0.5)
                }
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.surface1)
                }
                .transition(.opacity)
                //.opacity(1)
                .opacity(viewModel.syncStatus.isSyncing ? 1 : 0)
            Spacer()
        }
    }

    private var placeholderView: some View {
        ContentUnavailableView {
            Label("placeholder.no_places.title", systemImage: "mappin.slash")
        } description: {
            Text("placeholder.no_places.body")
        }
    }

    private var searchPlaceholderView: some View {
        ContentUnavailableView {
            Label("placeholder.no_places.title", systemImage: "exclamationmark.magnifyingglass")
        } description: {
            Text("placeholder.no_matching_places.body")
        }
    }

    private func placeRowView(_ place: PlaceUIModel) -> some View {
        placeRowContentView(place)
            .contextMenu(menuItems: {
                Button(action: { showOnMap(place.id) }) {
                    Text("common.show_on_map")
                }
            }, preview: {
                placeRowContentView(place)
                    .frame(width: UIScreen.main.bounds.width)
                    .environment(appSettings)
            })
            //.background(.backgroundPrimary)
            //.padding(.bottom, 20)
            // changeToken alone collides for two places with identical content
            // (e.g. duplicate imports with the same name/coords/tags/etc.) — pair
            // it with the place's own stable id so it stays globally unique while
            // still changing (forcing the refresh) whenever the content does.
            .id("\(place.id)-\(place.changeToken)")  // Force the update after edit
            .onTapGesture {
                selectedPlaceId = place.id
            }
    }
    
    private func placeRowContentView(_ place: PlaceUIModel) -> some View {
        PlaceRowView(place: place, locationManager: viewModel.locationManager)
//            .padding(EdgeInsets(top: 15,
//                                leading: 10,
//                                bottom: 15,
//                                trailing: 0))
            .contentShape(Rectangle()) // seems to fix the contextMenu not appearing on last item
    }
        
    // MARK: private methods
    private func showOnMap(_ placeId: UUID) {
        actionBus.send(.showOnMap(placeId: placeId))
    }
}

#if DEBUG
struct MockPlacesListView: View {
    var mock: MockContainer
    @State var places: [PlaceUIModel]
    @State var selectedPlaceId: UUID?
    @State var filter: PlaceFilter?

    var body: some View {
        mock.appContainer.createPlacesListView(places: places,
                                               allPlacesCount: places.count,
                                               selectedPlaceId: $selectedPlaceId,
                                               filter: $filter)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.places = mock.getAllPlaceUIModel()
        
        var filter = PlaceFilter()
        filter.tagIDs = Set<UUID>([UUID(), UUID(), UUID()])
        self._filter = State(initialValue: filter)
    }
}

#Preview {
    NavigationStack {
        TabView {
            MockPlacesListView()
                .tabItem {
                    Label("common.map", systemImage: "map")
                }
            Text(verbatim: "EmptyTab")
                .tabItem {
                    Label(String("Emptyti"), systemImage: "cross")
                }
        }
        .navigationTitle(String("Pipo"))
        .navigationBarTitleDisplayMode(.inline)
    }
    .environment(RootView.ActionBus())
    .environment(AppSettings())
}

#endif
