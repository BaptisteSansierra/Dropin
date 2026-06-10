//
//  GroupMapView.swift
//  Dropin
//
//  Created by baptiste sansierra on 3/6/26.
//

import SwiftUI

struct GroupMapView: View {
    
    @State private var viewModel: GroupMapViewModel

    init(viewModel: GroupMapViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        viewModel.createGenericMapView()
    }
}


#if false

@MainActor
@Observable class GroupMapViewModel {
    
    var groupId: UUID
    var loadingPlaces = false
    var places: [PlaceUI] = []
    var mapController: MapController
    var selectedPlaceId: UUID? = nil
    /// Current place detail sheet detent
    var detailSheetDetent: PresentationDetent = .medium

    @ObservationIgnored private var appContainer: AppContainer
    @ObservationIgnored private var fetchGroupPlaces: FetchGroupPlaces
    
    init(_ appContainer: AppContainer,
         groupId: UUID,
         fetchGroupPlaces: FetchGroupPlaces) {
        self.appContainer = appContainer
        self.groupId = groupId
        self.fetchGroupPlaces = fetchGroupPlaces
        self.mapController = MapController()
    }
    
    // MARK: UI Child
    func createPlaceSheetView(place: Binding<PlaceUI>, detent: Binding<PresentationDetent>) -> PlaceSheetView {
        return appContainer.createPlaceSheetView(place: place, detent: detent)
    }
    
    // MARK: use cases
    func fetchPlace() async throws {
        loadingPlaces = true
        places = try await fetchGroupPlaces(groupId)
            .map({ PlaceMapper.toUI($0) })
        loadingPlaces = false
    }
}


struct GroupMapView: View {
    
    @State private var viewModel: GroupMapViewModel

    init(viewModel: GroupMapViewModel) {
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

