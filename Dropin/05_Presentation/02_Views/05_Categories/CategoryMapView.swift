//
//  CategoryMapView.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/6/26.
//

import SwiftUI

struct CategoryMapView: View {
    
    @State private var viewModel: CategoryMapViewModel

    init(viewModel: CategoryMapViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        viewModel.createGenericMapView()
            .ignoresSafeArea()
    }
}


#if DEBUG

struct MockCategoryMapView: View {
    var mock: MockContainer
    @State private var category: CategoryUIModel

    var body: some View {
        mock.appContainer.createCategoryMapView(categoryId: category.id)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.category = mock.getCategoryUIModel()
    }
}

#Preview {
    NavigationStack {
        MockCategoryMapView()
    }
    .environment(AppSettings())
}

#endif


#if false

@MainActor
@Observable class CategoryMapViewModel {
    
    var categoryId: UUID
    var loadingPlaces = false
    var places: [PlaceUIModel] = []
    var mapController: MapController
    var selectedPlaceId: UUID? = nil
    /// Current place detail sheet detent
    var detailSheetDetent: PresentationDetent = .medium

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchCategoryPlaces: FetchCategoryPlaces
    
    init(_ appContainer: AppContainer,
         categoryId: UUID,
         fetchCategoryPlaces: FetchCategoryPlaces) {
        self.appContainer = appContainer
        self.categoryId = categoryId
        self.fetchCategoryPlaces = fetchCategoryPlaces
        self.mapController = MapController()
    }
    
    // MARK: UI Child
    func createPlaceSheetView(place: Binding<PlaceUIModel>, detent: Binding<PresentationDetent>) -> PlaceSheetView {
        return appContainer.createPlaceSheetView(place: place, detent: detent)
    }
    
    // MARK: use cases
    func fetchPlace() async throws {
        loadingPlaces = true
        places = try await fetchCategoryPlaces(categoryId)
            .map({ PlaceMapper.toUI($0) })
        loadingPlaces = false
    }
}


struct CategoryMapView: View {
    
    @State private var viewModel: CategoryMapViewModel

    init(viewModel: CategoryMapViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        PlacesMKMapVCR(config: .interactive, // .browse,
                       mapController: viewModel.mapController,
                       places: viewModel.places,
                       selectedPlaceId: $viewModel.selectedPlaceId,
                       onLongPress: nil,
                       onMapCameraUpdate: nil,
                       isSelectionEnabled: { true })
        .taskOnce {
            try? await viewModel.fetchPlace()
            try? await Task.sleep(for: .seconds(0.5))
            viewModel.mapController.fitAll(animated: true)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.mapController.fitAll(animated: true)
                } label: {
                    Image(systemName: "dot.arrowtriangles.up.right.down.left.circle")
                }
            }
        }

        /*
         // TODO: onChange of lastSync => reload places
         IS IT NEEDED ?
         
        .onChange(of: viewModel.syncStatus.lastSyncedAt) {
            Task {
                await reloadPlaces()
            }
        }
         */
        
        // Selected place sheet
        .sheet(item: $viewModel.selectedPlaceId,
               onDismiss: {
            viewModel.selectedPlaceId = nil
            viewModel.detailSheetDetent = .medium
        }) { placeId in
            createPlaceDetailsSheetView()
                .presentationDetents([.medium, .large], selection: $viewModel.detailSheetDetent)
                .presentationCornerRadius(20)
                .presentationBackground(.backgroundPrimary)
        }
    }
    
    // MARK: private methods
    private func createPlaceDetailsSheetView() -> PlaceSheetView {
        guard let selectedPlaceId = viewModel.selectedPlaceId else {
            fatalError("selectedPlaceId undefined")
        }
        guard let index = viewModel.places.firstIndex(where: { $0.id == selectedPlaceId }) else {
            fatalError("couldn't find place with id \(selectedPlaceId)")
        }
        return viewModel.createPlaceSheetView(place: $viewModel.places[index],
                                              detent: $viewModel.detailSheetDetent)
    }

}

#endif

