//
//  PlacesMapView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI
import MapKit
import CoreLocation
import SheetOverlay

struct PlacesMapView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: PlacesMapViewModel
    @Binding private var places: [PlaceUI]
    @Binding private var showingCreatePlaceMenu: Bool
    
    private var createPlaceSheetDefaultDetent: CGFloat = 400 // FIXME: rename? / move to VM?

    // MARK: - Init
    init(viewModel: PlacesMapViewModel,
         places: Binding<[PlaceUI]>,
         showingCreatePlaceMenu: Binding<Bool>) {
        self.viewModel = viewModel
        self._places = places
        self._showingCreatePlaceMenu = showingCreatePlaceMenu
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            creationDialogPlaceholderView
            
            PlacesMapViewRepresentable(viewModel: viewModel,
                                       places: $places)

            if viewModel.pickingAddress || viewModel.pickingCoordinates {
                pickingMarkerView
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            onAppearCallback()
        }
        // Overlays
        .overlay {
            MapSettingsOverlay(settingsShown: $viewModel.mapSettings.settingsShown,
                               hidePointsOfInterest: $viewModel.mapSettings.hidePointsOfInterest,
                               satellite: $viewModel.mapSettings.satellite)
        }
        .overlay {
            zoomOnUserOverlay
        }
        // Sheets
        .sheet(isPresented: $viewModel.showQuickCreateSheet, onDismiss: {
            viewModel.discardCreation()
            // Load the possible created place
            Task {
                await reloadPlaces()
            }
        }, content: {
            viewModel.createPlaceCreateQuickView()
                .presentationDetents([.height(createPlaceSheetDefaultDetent), .large])
        })
        .sheet(item: $viewModel.selectedPlaceId,
               onDismiss: {
            viewModel.detailSheetDetent = .medium
            viewModel.clearSelection()
        }) { placeId in
            createPlaceDetailsSheetView()
                .presentationDetents([.medium, .large], selection: $viewModel.detailSheetDetent)
                .presentationCornerRadius(20)
                .presentationBackground(.backgroundPrimary)
        }
        .sheetOverlay(isPresented: $viewModel.pickingAddress) {
            AddressPickerView(coords: $viewModel.addressPickerCoords,
                              address: $viewModel.pickedAddress,
                              //onFetchAddress: onAddressPickerFetchAddress,
                              onComplete: onAddressPickerComplete)
            .sheetOverlayDetents([.height(viewModel.pickingAddress ? viewModel.addressSheetHeight : viewModel.coordinatesSheetHeight)])
            .sheetOverlayDragIndicator(.visible)
        }
    }
    
    // MARK: - UI
    private var creationDialogPlaceholderView: some View {
        // Create an hidden rectangle over the (+) nav bar button
        // So the dialog can be anchored on it (FIXME: anchor on the right button)
        VStack {
            HStack {
                Spacer()
                Rectangle()
                    .frame(width: 45, height: 45)
                    .padding()
                    .confirmationDialog("common.save_new_place",
                                        isPresented: $showingCreatePlaceMenu,
                                        titleVisibility: .visible,
                                        actions: createNewPlaceActions)
            }
            .frame(height: 60)
            Spacer()
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func createNewPlaceActions() -> some View {
        // Create place from input string
        Button {
            viewModel.pushLookupPlacesView()
        } label: {
            Text("menu.new_place.adress")
                .textStyle(.body)
        }
        // Create place from here now
        Button {
            guard let _ = viewModel.locationManager.authorized else {
                viewModel.showAuthLocAlert.toggle()
                return
            }
            guard let location = viewModel.locationManager.lastKnownLocation else { return }
            prepareCreatePlaceFromCoords(location)
        } label: {
            Text("menu.new_place.current")
                .textStyle(.body)
        }
        // Create place from moving map under cursor
        Button {
            viewModel.pickedAddress = nil
            viewModel.pickingAddress.toggle()
        } label: {
            Text("menu.new_place.drop_pin")
                .textStyle(.body)
        }
        // Create place from lat/long
        Button {
        } label: {
            Text("menu.new_place.coords")
                .textStyle(.body)
        }
        // Create place from contact
        Button {
        } label: {
            Text("menu.new_place.contact")
                .textStyle(.body)
        }
        // Create place from a pic
        Button {
        } label: {
            // Does this make sense ?
            // only when image supported maybe
            Text("menu.new_place.image_library")
                .textStyle(.body)
        }
    }

    private var zoomOnUserOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if let locauthorized = viewModel.locationManager.authorized, locauthorized {
                    if let userLoc = viewModel.locationManager.lastKnownLocation {
                        MapIcoButton(systemImage: "location.fill",
                                     offset: CGPoint(x: -1, y: 1),
                                     imageFrame: CGSize(width: 15, height: 15)) {
                            viewModel.centerOnUser()
                            //viewModel.mapSettings.position = .camera(MapCamera(centerCoordinate: userLoc, distance: 5000))
                        }
                        .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                    }
                } else {
                    MapIcoButton(systemImage: "exclamationmark.triangle",
                                 offset: CGPoint(x: 0, y: -1),
                                 imageFrame: CGSize(width: 15, height: 15),
                                 color: .warning) {
                        viewModel.showAuthLocAlert.toggle()
                    }
                    .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                    .alert("common.loc_auth_missing", isPresented: $viewModel.showAuthLocAlert) {
                        Button("common.open_settings") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(url)
                        }
                        Button("common.cancel") {}
                    } message: {
                        Text("common.loc_auth_required")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var pickingMarkerView: some View {
        let markerSize: CGFloat = 36
        MapPinView(icon: Icon(rawValue: "sf:pin"))
            .frame(width: markerSize, height: markerSize)
            .offset(x: 0,
                    y: viewModel.addressPickerViewCoords.y - markerSize * 0.5)
    }

    // MARK: private methods
    private func onAppearCallback() {
        guard let lastNavigationSource = viewModel.coordinator.lastNavigationSource else {
            print("Navigation history EMPTY")
            return
        }
        switch lastNavigationSource {
            case .placeCreateView, .placeEditView:
                Task {
                    await reloadPlaces()
                }
            default:
                ()
        }
    }
    
    private func reloadPlaces() async {
        do {
            places = try await viewModel.loadPlaces()
            viewModel.reloadMapData()
        } catch {
            assertionFailure("couldn't reload places")
        }
    }

    private func prepareCreatePlaceFromCoords(_ coordinates: CLLocationCoordinate2D) {
        let createdPlace = viewModel.preparePlaceFromCoords(coords: coordinates)
        // Show the creation sheet
        viewModel.showQuickCreateSheet.toggle()
        // Center map on new place
        viewModel.centerOnCoords(coordinates, sheetHeight: 400) // FIXME: 400
    }
    
    private func onAddressPickerComplete() {
        _ = viewModel.preparePlaceFromAddress(coords: viewModel.addressPickerCoords,
                                              address: viewModel.pickedAddress)
        // Reset picked address
        viewModel.pickedAddress = nil
        // Hide pickingAddress sheet
        viewModel.pickingAddress.toggle()
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            // Show the creation sheet
            viewModel.showQuickCreateSheet.toggle()
        }
    }

}

// Create Views
extension PlacesMapView {
    
    private func createPlaceDetailsSheetView() -> PlaceSheetView {
        guard let selectedPlaceId = viewModel.selectedPlaceId else {
            fatalError("selectedPlaceId undefined")
        }
        guard let index = places.firstIndex(where: { $0.id == selectedPlaceId }) else {
            fatalError("couldn't find place with id \(selectedPlaceId)")
        }
        return viewModel.createPlaceSheetView(place: $places[index],
                                              detend: $viewModel.detailSheetDetent)
    }
}




#if DEBUG
struct MockPlacesMapView: View {
    var mock: MockContainer
    @State var places: [PlaceUI]
    @State var showingCreatePlaceMenu: Bool = false

    var body: some View {
        mock.appContainer.createPlacesMapView(places: $places,
                                              showingCreatePlaceMenu: $showingCreatePlaceMenu)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.places = mock.getAllPlaceUI()
    }
}

#Preview {
    NavigationStack {
        MockPlacesMapView()
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#endif

