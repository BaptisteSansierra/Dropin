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
    private var places: [PlaceUI]

    // MARK: - Init
    init(viewModel: PlacesListViewModel,
         places: [PlaceUI],
         selectedPlaceId: Binding<UUID?>) {
        self.viewModel = viewModel
        self.places = places
        self._selectedPlaceId = selectedPlaceId
    }
    
    // MARK: - Body
    var body: some View {
        if places.isEmpty {
            placeholderView
        } else {
            contentView
        }
    }
    
    // MARK: - Subviews
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(places) { place in
                    if place.isActive {
                        placeRowView(place)
                    }
                }
            }
        }
        //.scrollPosition($scrollPosition)
        .background(.backgroundSecondary)
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

    private func placeRowView(_ place: PlaceUI) -> some View {
        placeRowContentView(place)
            .contextMenu(menuItems: {
                Button(action: {showOnMap(place.id)}) {
                    Text("common.show_on_map")
                }
            }, preview: {
                placeRowContentView(place)
                    .frame(width: UIScreen.main.bounds.width)
                    .environment(appSettings)
            })
            .background(.backgroundPrimary)
            .padding(.bottom, 20)
            .id(place.changeToken)  // Force the update after edit
            .onTapGesture {
                selectedPlaceId = place.id
            }
    }
    
    private func placeRowContentView(_ place: PlaceUI) -> some View {
        PlaceRowView(place: place, locationManager: viewModel.locationManager)
            .padding(EdgeInsets(top: 15,
                                leading: 10,
                                bottom: 15,
                                trailing: 0))
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
    @State var places: [PlaceUI]
    @State var selectedPlaceId: UUID?

    var body: some View {
        mock.appContainer.createPlacesListView(places: places, selectedPlaceId: $selectedPlaceId)
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
}

#endif
