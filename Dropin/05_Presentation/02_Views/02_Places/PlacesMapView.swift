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
    @Binding private var selectedPlaceId: UUID?
    /// True if parent is presenting something over the view (sidebar / menu / ...) => should hide sheetOverlays
    @Binding private var isParentPresenting: Bool
    @Binding private var showingCreatePlaceMenu: Bool
    @Environment(RootView.ActionBus.self) private var actionBus
    @Environment(AppSettings.self) private var appSettings

    // MARK: - Properties
    private var places: [PlaceUI]
    private var createPlaceSheetDefaultDetent: CGFloat = 400 // FIXME: rename? / move to VM?
    private var navBarHeight: CGFloat
    private var mapReloadGen: Int
    private var isActiveTab: Bool

    // MARK: - Init
    init(viewModel: PlacesMapViewModel,
         places: [PlaceUI],
         selectedPlaceId: Binding<UUID?>,
         isParentPresenting: Binding<Bool>,
         showingCreatePlaceMenu: Binding<Bool>,
         mapReloadGen: Int,
         navBarHeight: CGFloat,
         isActiveTab: Bool = true) {
        self.viewModel = viewModel
        self.places = places
        self._selectedPlaceId = selectedPlaceId
        self._isParentPresenting = isParentPresenting
        self._showingCreatePlaceMenu = showingCreatePlaceMenu
        self.mapReloadGen = mapReloadGen
        self.navBarHeight = navBarHeight
        self.isActiveTab = isActiveTab
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { proxy in
            
            ZStack(alignment: .top) {
                creationDialogPlaceholderView
                
                // Map with bottom inset for card
                PlacesMKMapVCR(config: viewModel.launchConfig,
                               mapController: viewModel.mapController,
                               places: places,
                               draftCoordinate: viewModel.draftPlace?.coordinates,
                               selectedPlaceId: $selectedPlaceId,
                               onLongPress: viewModel.onLongPress,
                               onMapCameraUpdate: viewModel.onCameraUpdate,
                               interactionStatus: viewModel.interactionStatus,
                               mapReloadGen: mapReloadGen,
                               bottomInset: DropinApp.ui.mainTabBarHeight - UIApplication.rootBottomSafeArea(),
                               isActiveTab: isActiveTab,
                               pinsOpacity: 1.0) // TODO: FIXME: lower pins opacity when address picker is presented
                               //pinsOpacity: viewModel.pickingAddress ? 0.5 : 1.0)
                 
                if viewModel.pickingAddress {
                    pickingMarkerView
                        .allowsHitTesting(false)
                }
            }
        }
        .onReceive(actionBus.actionPublisher) { handleAction($0) }
        .onChange(of: isParentPresenting, { oldValue, newValue in
            guard isParentPresenting else { return }
            isParentPresenting.toggle()
            viewModel.pickingAddress = false
        })
        // Overlays
        .overlay {
            MapSettingsOverlay(settingsShown: $viewModel.mapConfig.settingsShown)
                .padding(.top, navBarHeight)
        }
        .overlay {
            zoomOnUserOverlay
        }
        // Sheets
        .sheet(isPresented: $viewModel.showQuickCreateSheet, onDismiss: {
            viewModel.discardDraftPlace()
            // Load the possible created place
            actionBus.send(.reloadMainPlaces)
        }, content: {
            viewModel.createPlaceCreateQuickView()
                .presentationDetents([PlaceCreateQuickView.sheetHeight])
                .presentationDragIndicator(.visible)
        })
        .sheetOverlay(isPresented: $viewModel.pickingAddress) {
            return AddressPickerView(editCoords: viewModel.pickingAddressWithCoords,
                                     coords: $viewModel.addressPickerCoords,
                                     address: $viewModel.pickedAddress,
                                     fetching: $viewModel.fetchingAddressPicker,
                                     isPresented: $viewModel.pickingAddress,
                                     onCoordsEdit: onAddressPickerCoordsEdit,
                                     onComplete: onAddressPickerComplete)
            .sheetOverlayDetents([.height(DropinApp.ui.addressPickerSheetHeight)])
            .sheetOverlayDragIndicator(.visible)
            .sheetOverlayKeyboardPolicy(.maxOffset(100))
            .id(viewModel.pickingAddressWithCoords)
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
            viewModel.pickingAddressWithCoords = false
            viewModel.pickingAddress.toggle()
        } label: {
            Text("menu.new_place.drop_pin")
                .textStyle(.body)
        }
        // Create place from lat/long
        Button {
            viewModel.pickedAddress = nil
            viewModel.pickingAddressWithCoords = true
            viewModel.pickingAddress.toggle()
        } label: {
            Text("menu.new_place.coords")
                .textStyle(.body)
        }
        #if false // TODO: DRO-32 > implement place creation from contact / image
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
        #endif
    }

    private var zoomOnUserOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if let locauthorized = viewModel.locationManager.authorized, locauthorized {
                    if let _ = viewModel.locationManager.lastKnownLocation {
                        MapIcoButton(systemImage: "location.fill",
                                     offset: CGPoint(x: -1, y: 1),
                                     imageFrame: CGSize(width: 15, height: 15)) {
                            viewModel.centerOnUser()
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
        let markerSize: CGFloat = appSettings.mapSettings.pinSize
        let offsetY: CGFloat = viewModel.addressPickerViewCoords.y
        MapPinView(icon: Icon(rawValue: "sf:pin"))
            .frame(width: markerSize, height: markerSize)
            .offset(x: 0,
                    y: offsetY - markerSize)
    }

    // MARK: private methods
    private func handleAction(_ action: RootView.ActionBus.Action) {
        switch action {
            case .showOnMap(let placeId):
                selectedPlaceId = placeId
            default:
                ()
        }
    }

    private func prepareCreatePlaceFromCoords(_ coordinates: CLLocationCoordinate2D) {
        viewModel.preparePlaceFromCoords(coords: coordinates)
        // Show the creation sheet
        viewModel.showQuickCreateSheet.toggle()
        // Center map on new place
        viewModel.centerOn(coordinates)
    }
    
    private func onAddressPickerCoordsEdit(_ coords: CLLocationCoordinate2D) {
        viewModel.coordinatesPickerUpdate(coords)
    }

    private func onAddressPickerComplete() {
        onAddressPickerComplete(viewModel.addressPickerCoords)
    }

    private func onAddressPickerComplete(_ coordinates: CLLocationCoordinate2D) {
        viewModel.preparePlaceFromAddress(coords: coordinates,
                                          address: viewModel.pickedAddress)
        // Reset picked address
        viewModel.pickedAddress = nil
        // Hide sheet
        viewModel.pickingAddress = false
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            // Show the creation sheet
            viewModel.showQuickCreateSheet.toggle()
        }
    }
}

#if DEBUG
struct MockPlacesMapView: View {
    var mock: MockContainer
    @State var places: [PlaceUI]
    @State var selectedPlaceId: UUID? = nil
    @State var isParentPresenting: Bool = false
    @State var showingCreatePlaceMenu: Bool = false

    var body: some View {
        mock.appContainer.createPlacesMapView(places: places,
                                              selectedPlaceId: $selectedPlaceId,
                                              isParentPresenting: $isParentPresenting,
                                              showingCreatePlaceMenu: $showingCreatePlaceMenu,
                                              mapReloadGen: Int.zero,
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
    .environment(AppSettings())
    .environment(RootView.ActionBus())
}

#endif

