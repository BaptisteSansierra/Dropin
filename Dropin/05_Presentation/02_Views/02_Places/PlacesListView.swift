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
    @Environment(RootView.ActionBus.self) private var actionBus
    @Environment(AppSettings.self) private var appSettings

    // MARK: - Properties
    private var places: [PlaceUIModel]
    private var activePlaces: [PlaceUIModel] {
        places.filter { $0.isActive }
    }

    // MARK: - Init
    init(viewModel: PlacesListViewModel,
         places: [PlaceUIModel],
         selectedPlaceId: Binding<UUID?>) {
        self.viewModel = viewModel
        self.places = places
        self._selectedPlaceId = selectedPlaceId
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
//            Rectangle()
//                .fill(.fieldBorder)
//                .frame(height: 1)
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(activePlaces) { place in
                        placeRowView(place)
                    }
                }
                .padding(.top)
                .padding(.horizontal)
                .padding(.bottom, 20)

            }
            //.scrollPosition($scrollPosition)
        }
        .background(.backgroundPrimary)
        .safeAreaPadding(.bottom, DropinApp.ui.mainTabBarHeight)
        .ignoresSafeArea(edges: .bottom)
    }

    private var placeholderView: some View {
        ContentUnavailableView {
            Label("placeholder.no_places.title", systemImage: "mappin.slash")
        } description: {
            Text("placeholder.no_places.body")
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

    var body: some View {
        mock.appContainer.createPlacesListView(places: places, selectedPlaceId: $selectedPlaceId)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.places = mock.getAllPlaceUIModel()
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
