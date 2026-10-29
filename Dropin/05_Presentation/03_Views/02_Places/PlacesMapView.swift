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
    @Binding private var filter: PlaceFilter?
    /// True if parent is presenting something over the view (sidebar / menu / ...) => should hide sheetOverlays
    @Binding private var isParentPresenting: Bool
    @Binding private var showingCreatePlaceMenu: Bool
    @Binding private var draftPlace: PlaceUIModel?
    @Binding private var draftPlacePoiCategory: MKPointOfInterestCategory?
    @Binding private var draftPlacePoiColor: Color?

    @Environment(RootView.ActionBus.self) private var actionBus
    @Environment(AppSettings.self) private var appSettings

    // MARK: - Properties
    private var places: () -> [PlaceUIModel]
    private var allPlacesCount: Int
    private var createPlaceSheetDefaultDetent: CGFloat = 400 // FIXME: rename? / move to VM?
    private var navBarHeight: CGFloat
    private var mapReloadGen: Int
    private var isActiveTab: Bool

    // MARK: - Init
    init(viewModel: PlacesMapViewModel,
         places: @escaping () -> [PlaceUIModel],
         allPlacesCount: Int,
         draftPlace: Binding<PlaceUIModel?>,
         draftPlacePoiCategory: Binding<MKPointOfInterestCategory?>,
         draftPlacePoiColor: Binding<Color?>,
         selectedPlaceId: Binding<UUID?>,
         filter: Binding<PlaceFilter?>,
         isParentPresenting: Binding<Bool>,
         showingCreatePlaceMenu: Binding<Bool>,
         mapReloadGen: Int,
         navBarHeight: CGFloat,
         isActiveTab: Bool = true) {
        self.viewModel = viewModel
        self.places = places
        self.allPlacesCount = allPlacesCount
        self._draftPlace = draftPlace
        self._draftPlacePoiCategory = draftPlacePoiCategory
        self._draftPlacePoiColor = draftPlacePoiColor
        self._selectedPlaceId = selectedPlaceId
        self._filter = filter
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
                               places: places(),
                               draftCoordinate: draftPlace?.coordinates,
                               selectedPlaceId: $selectedPlaceId,
                               selectedApplePOI: $viewModel.selectedApplePOI,
                               onLongPress: onLongPress,
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
                
                headerOverlayView
                    .padding(.top, navBarHeight)
            }
        }
        .onAppear {
            onAppearCallback()
        }
        .onReceive(actionBus.actionPublisher) { handleAction($0) }
        .onChange(of: isParentPresenting, { oldValue, newValue in
            guard isParentPresenting else { return }
            isParentPresenting.toggle()
            viewModel.pickingAddress = false
        })
        .onChange(of: viewModel.selectedApplePOI, { oldValue, newValue in
            // Wrap the Apple annotation to an identifiable object
            guard let poi = newValue else {
                viewModel.selectedIdfApplePOI = nil
                return
            }
            viewModel.selectedIdfApplePOI = IdentifiablePOI(annotation: poi)
        })
        // Overlays
        .overlay {
            MapSettingsOverlay()
                .padding(.top, navBarHeight)
        }
        .overlay {
            zoomOnUserOverlay
        }
        // Sheets
        .sheet(item: $viewModel.selectedIdfApplePOI,
               onDismiss: {
                   viewModel.selectedApplePOI = nil
                   if let _ = draftPlace {
                       // If a draft place was created, present the quick creation sheet
                       viewModel.presentQuickCreateSheet(draftPlace: $draftPlace, places: places())
                   }
               }, content: { selectedApplePOI in
                   viewModel.createApplePOISheetView(draftPlace: $draftPlace,
                                                     draftPlacePoiCategory: $draftPlacePoiCategory,
                                                     draftPlacePoiColor: $draftPlacePoiColor)
                       .presentationDetents([.medium])
                       .presentationDragIndicator(.visible)
                       .presentationBackground(.surface1)
               })
        .sheet(isPresented: $viewModel.showQuickCreateSheet, onDismiss: {
            switch viewModel.quickCreateResult {
                case .moreOptions:
                    // user asked for more creation options, we keep the draft to present it in detailed view
                    // Data coming from Apple POI are already consumed, they can be reset
                    discardApplePOISuggestions()
                case .saved:
                    // reload places and discard draft
                    actionBus.send(.reloadMainPlaces)
                    discardDraftPlace()
                case .none:
                    // sheet was swiped down, discard draft
                    discardDraftPlace()
            }
        }, content: {
            viewModel.createPlaceCreateQuickView(draftPlace: $draftPlace,
                                                 draftPlacePoiCategory: draftPlacePoiCategory,
                                                 draftPlacePoiColor: draftPlacePoiColor)
                .presentationDetents([PlaceCreateQuickView.sheetHeight])
                .presentationDragIndicator(.visible)
        })
        .alertOk(isPresented: $viewModel.isPresentingDuplicatingPlace,
                 title: "places_map_view.create_place_error.title",
                 body: LocalizedStringKey(String(format: NSLocalizedString("places_map_view.duplicate_place.body.%@", comment: ""),
                                                 viewModel.duplicatingPlace?.name ?? "")))
        .alertOk(isPresented: $viewModel.isPresentingOverlapingPlace,
                 title: "places_map_view.create_place_error.title",
                 body: LocalizedStringKey(String(format: NSLocalizedString("places_map_view.overlap_place.body.%@", comment: ""),
                                                 viewModel.overlapingPlace?.name ?? "")))
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
    
    // MARK: - Subviews
    @ViewBuilder
    private var headerOverlayView: some View {
        VStack(spacing: 0) {
            if let filter = filter {
                filterView(filter)
                    .padding(.bottom, 10)
            }
            syncingView
        }
        .padding(.top)
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
                .fill(.surface1)
                .stroke(.dropinPrimary)
        }
        .onTapGesture {
            self.filter = nil
        }
    }
    
    private var syncingView: some View {
        Text("main.syncing")
            .textStyle(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .keyframeAnimator(initialValue: 0.15, repeating: true) { view, opacity in
                view.opacity(opacity)          // text blinks
            } keyframes: { _ in
                LinearKeyframe(0.5, duration: 0.5)
                LinearKeyframe(0.15, duration: 0.5)
            }
            .background {
                Capsule()
                    .fill(.surface1)
            }
            .opacity(viewModel.syncStatus.isSyncing ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: viewModel.syncStatus.isSyncing)
    }

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
            guard viewModel.locationManager.isAuthorized else {
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
                if viewModel.locationManager.isAuthorized {
                    if let _ = viewModel.locationManager.lastKnownLocation {
                        MapIcoButton(systemImage: "location.fill") {
                            viewModel.centerOnUser()
                        }
                        .padding(EdgeInsets(top: 15,
                                            leading: 10,
                                            bottom: 15 + DropinApp.ui.mainTabBarHeight,
                                            trailing: 10))
                    }
                } else {
                    MapIcoButton(systemImage: "exclamationmark.triangle",
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
        viewModel.preparePlaceFromCoords(coords: coordinates, draftPlace: $draftPlace)
        // Show the creation sheet
        viewModel.presentQuickCreateSheet(draftPlace: $draftPlace, places: places())
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
                                          address: viewModel.pickedAddress,
                                          draftPlace: $draftPlace)
        // Reset picked address
        viewModel.pickedAddress = nil
        // Hide sheet
        viewModel.pickingAddress = false
        Task {
            try? await Task.sleep(for: .seconds(0.35))
            // Show the creation sheet
            viewModel.presentQuickCreateSheet(draftPlace: $draftPlace, places: places())
        }
    }
    
    private func onLongPress(coords: CLLocationCoordinate2D) -> Void {
        viewModel.onLongPress(coords: coords, draftPlace: $draftPlace, places: places())
    }
    
    private func discardApplePOISuggestions() {
        draftPlacePoiCategory = nil
        draftPlacePoiColor = nil
    }

    private func discardDraftPlace() {
        draftPlace = nil
        discardApplePOISuggestions()
    }
    
    private func onAppearCallback() {
        guard let lastNavigationSource = viewModel.coordinator.lastNavigationSource else {
            return
        }
        switch lastNavigationSource {
            case .lookupPlacesView:
                if let _ = draftPlace {
                    // If a draft place was created during lookup, present the quick creation sheet
                    viewModel.presentQuickCreateSheet(draftPlace: $draftPlace, places: places())
                }
            default:
                print("ignore lastNavigationSource = \(lastNavigationSource)")
                ()
        }
    }
}

#if DEBUG
struct MockPlacesMapView: View {
    var mock: MockContainer
    @State var places: [PlaceUIModel]
    @State var selectedPlaceId: UUID? = nil
    @State var isParentPresenting: Bool = false
    @State var showingCreatePlaceMenu: Bool = false
    @State var filter: PlaceFilter?

    var body: some View {
        mock.appContainer.createPlacesMapView(places: { places },
                                              allPlacesCount: places.count,
                                              draftPlace: .constant(nil),
                                              draftPlacePoiCategory: .constant(nil),
                                              draftPlacePoiColor: .constant(nil),
                                              selectedPlaceId: $selectedPlaceId,
                                              filter: $filter,
                                              isParentPresenting: $isParentPresenting,
                                              showingCreatePlaceMenu: $showingCreatePlaceMenu,
                                              mapReloadGen: Int.zero,
                                              navBarHeight: 100)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.places = mock.getAllPlaceUIModel()

        // Create a fake filter
        var filter = PlaceFilter()
        filter.tagIDs = Set<UUID>([UUID(), UUID(), UUID()])
        self._filter = State(initialValue: filter)
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

