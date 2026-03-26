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
    /// True if parent is presenting something over the view (sidebar / menu / ...) => should hide sheetOverlays
    @Binding private var isParentPresenting: Bool
    @Binding private var showingCreatePlaceMenu: Bool
    @Environment(RootView.ActionBus.self) private var actionBus
    
    private var createPlaceSheetDefaultDetent: CGFloat = 400 // FIXME: rename? / move to VM?
    private var navBarHeight: CGFloat

    // MARK: - Init
    init(viewModel: PlacesMapViewModel,
         places: Binding<[PlaceUI]>,
         isParentPresenting: Binding<Bool>,
         showingCreatePlaceMenu: Binding<Bool>,
         navBarHeight: CGFloat) {
        self.viewModel = viewModel
        self._places = places
        self._isParentPresenting = isParentPresenting
        self._showingCreatePlaceMenu = showingCreatePlaceMenu
        self.navBarHeight = navBarHeight
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { proxy in
            
            ZStack(alignment: .top) {
                creationDialogPlaceholderView
                
                // Map with bottom inset for card
                PlacesMapViewVCRepresentable(viewModel: viewModel,
                                             places: $places,
                                             //topInset: 0,
                                             bottomInset: DropinApp.ui.mainTabBarHeight - UIApplication.rootBottomSafeArea())
                
                if viewModel.pickingAddress || viewModel.pickingCoordinates {
                    pickingMarkerView
                        .allowsHitTesting(false)
                }
            }
        }
        .onReceive(actionBus.actionPublisher) { handleAction($0) }
        .onAppear {
            onAppearCallback()
        }
        .onChange(of: isParentPresenting, { oldValue, newValue in
            guard isParentPresenting else { return }
            isParentPresenting.toggle()
            viewModel.pickingAddress = false
            viewModel.pickingCoordinates = false
        })
        // Overlays
        .overlay {
            MapSettingsOverlay(settingsShown: $viewModel.mapSettings.settingsShown,
                               hidePointsOfInterest: $viewModel.mapSettings.hidePointsOfInterest,
                               satellite: $viewModel.mapSettings.satellite)
            .padding(.top, navBarHeight)
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
                              //onFetch: { },
                              onComplete: onAddressPickerComplete)
            .sheetOverlayDetents([.height(DropinApp.ui.addressPickerSheetHeight)])
            .sheetOverlayDragIndicator(.visible)
        }
        .sheetOverlay(isPresented: $viewModel.pickingCoordinates) {
            CoordinatesPickerView(coords: Binding<CLLocationCoordinate2D>(get: {
                viewModel.coordinatesPickerCoords
            }, set: { edited in
                Log.debug("SET COORDS : \(edited)")
                viewModel.coordinatesPickerUpdate(edited)
            }),
                                  address: $viewModel.pickedAddress,
                                  onComplete: onCoordinatesPickerComplete)
            .sheetOverlayDetents([.height(DropinApp.ui.coordinatesPickerSheetHeight)])
            .sheetOverlayDragIndicator(.visible)
            .sheetOverlayKeyboardPolicy(.maxOffset(100))
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
            viewModel.pickedAddress = nil
            viewModel.pickingCoordinates.toggle()
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
                        .padding(EdgeInsets(top: 15,
                                            leading: 10,
                                            bottom: 15 + DropinApp.ui.mainTabBarHeight,
                                            trailing: 10))
                    }
                } else {
                    MapIcoButton(systemImage: "exclamationmark.triangle",
                                 offset: CGPoint(x: 0, y: -1),
                                 imageFrame: CGSize(width: 15, height: 15),
                                 color: .warning) {
                        viewModel.showAuthLocAlert.toggle()
                    }
                    .padding(EdgeInsets(top: 15,
                                        leading: 10,
                                        bottom: 15 + DropinApp.ui.mainTabBarHeight,
                                        trailing: 10))
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
        let markerSize: CGFloat = DropinApp.ui.pinHeight
        let offsetY: CGFloat = viewModel.pickingAddress ?
                                viewModel.addressPickerViewCoords.y :
                                viewModel.coordinatesPickerViewCoords.y
        MapPinView(icon: Icon(rawValue: "sf:pin"))
            .frame(width: markerSize, height: markerSize)
            .offset(x: 0,
                    y: offsetY - markerSize)
    }

    // MARK: private methods
    private func handleAction(_ action: RootView.ActionBus.Action) {
        switch action {
            case .showOnMap(let placeId):
                viewModel.manualSelectPlace(placeId)
            default:
                ()
        }
    }

    private func onAppearCallback() {
        guard let lastNavigationSource = viewModel.coordinator.lastNavigationSource else {
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
        let _ = viewModel.preparePlaceFromCoords(coords: coordinates)
        // Show the creation sheet
        viewModel.showQuickCreateSheet.toggle()
        // Center map on new place
        viewModel.centerOnCoords(coordinates, sheetHeight: 400) // FIXME: 400
    }
    
    private func onAddressPickerComplete() {
        onPlacePickerComplete(viewModel.addressPickerCoords)
    }

    private func onCoordinatesPickerComplete() {
        onPlacePickerComplete(viewModel.coordinatesPickerCoords)
    }

    private func onPlacePickerComplete(_ coordinates: CLLocationCoordinate2D) {
        _ = viewModel.preparePlaceFromAddress(coords: coordinates,
                                              address: viewModel.pickedAddress)
        // Reset picked address
        viewModel.pickedAddress = nil
        // Hide sheet
        viewModel.pickingAddress = false
        viewModel.pickingCoordinates = false
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
    @State var isParentPresenting: Bool = false
    @State var showingCreatePlaceMenu: Bool = false

    var body: some View {
        mock.appContainer.createPlacesMapView(places: $places,
                                              isParentPresenting: $isParentPresenting,
                                              showingCreatePlaceMenu: $showingCreatePlaceMenu,
                                              navBarHeight: 100)
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

