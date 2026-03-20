//
//  PlacesMapView.OLD.swift
//  Dropin
//
//  Created by baptiste sansierra on 18/3/26.
//



#if false

import CoreLocation
import MapKit
import ClusterMapSwiftUI
import SheetOverlay

struct PlacesMapView: View {

// MARK: - State & Bindings
@State private var viewModel: PlacesMapViewModel
@Binding private var places: [PlaceUI]
@Binding private var showingCreatePlaceMenu: Bool

// TODO: move states to view model
@State private var showingQuickCreateSheet = false
@State private var showAuthLocAlert = false
// Long press behaviour
@State private var longPressGestureDateStart: Date?
@State private var longPressGestureCanceled = false
@State private var longPressGestureLocation: CGPoint?
@State private var longPressTimer = Timer.publish(every: 100, on: .main, in: .common).autoconnect()

// MARK: - private var
private let zoomMapDuration: TimeInterval = 10
//private var createPlaceSheetDefaultDetent: CGFloat = 0.6
private var createPlaceSheetDefaultDetent: CGFloat = 400

private var addressSheetHeight: CGFloat = 350
private var coordinatesSheetHeight: CGFloat = 400

// MARK: - Init
init(viewModel: PlacesMapViewModel,
     places: Binding<[PlaceUI]>,
     showingCreatePlaceMenu: Binding<Bool>) {
    self.viewModel = viewModel
    self._places = places
    self._showingCreatePlaceMenu = showingCreatePlaceMenu
}

// MARK: - Body
#if true
var body: some View {
    PlacesMapViewRepresentable(viewModel: viewModel,
                               places: $places)
}
#else
var body: some View {
    mapReaderView
        .onAppear {
            onAppearCallback()
        }
        .readSize(onChange: { newValue in
            viewModel.dataSource.mapSize = newValue
        })
}
#endif

// MARK: - Subviews
private var mapReaderView: some View {
    ZStack {
        creationDialogPlaceholderView
        
        MapReader { proxy in
            mapView(proxy: proxy)
        }
    }
    .safeAreaInset(edge: .bottom, content: {
        Color.clear
            .frame(height: 40)
    })
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
        guard let _ = viewModel.locationManager.authorized else {
            showAuthLocAlert.toggle()
            return
        }
        guard let location = viewModel.locationManager.lastKnownLocation else { return }
        prepareCreatePlaceFromCoords(location)
    } label: {
        Text("menu.new_place.current")
            .textStyle(.body)
    }
    
    // Create place from lat/long
    Button {
    } label: {
        Text("menu.new_place.coords")
            .textStyle(.body)
    }
    // Create place from moving map under cursor
    Button {
        viewModel.pickedAddress = nil
        updateAddressPickerCoords()
        viewModel.pickingAddress.toggle()
    } label: {
        Text("menu.new_place.drop_pin")
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
//        Button("RANDOM COORDS") {
//                guard let loc = locationManager.lastKnownLocation else {
//                    print("Unknown loc")
//                    return
//                }
//                let latitude = loc.latitude + Double.random(in: -0.02...0.01)
//                let longitude = loc.longitude + Double.random(in: -0.02...0.01)
//                let item = SDPlace(name: "random\(Int.random(in: 100...999))", latitude: latitude, longitude: longitude, address: "")
//                modelContext.insert(item)
//        }.disabled(true)
}

private func mapView(proxy: MapProxy) -> some View {
    ZStack(alignment: .center) {
        stateObservers

        Map(position: $viewModel.mapSettings.position) {
            
            if !viewModel.pickingAddress && !viewModel.pickingCoordinates {
                mapContent
            } else {
                Marker("BCN", coordinate: CLLocationCoordinate2D.barcelona)
            }
            UserAnnotation()
            
        }
        if viewModel.pickingAddress || viewModel.pickingCoordinates {
            pickingMarkerView
                .allowsHitTesting(false)
        }
    }
    .onFirstAppear(onFirstAppear)
    .mapControls {
        MapCompass()
    }
    .mapStyle(viewModel.mapSettings.selectedMapStyle)
    .onMapCameraChange(frequency: .continuous) { ctx in
        // Cancel long press timer when moving map camera
        longPressTimer.upstream.connect().cancel()

        // Reset picking address value
        if viewModel.pickingAddress {
            viewModel.pickedAddress = nil
            updateAddressPickerCoords(camera: ctx.camera, span: ctx.region.span)
        }
    }
    .onMapCameraChange(frequency: .onEnd) { ctx in
        Task {
            await viewModel.dataSource.reloadAnnotations(region: ctx.region)
        }
        updateCameraCache(ctx)
        if viewModel.pickingAddress {
            updateAddressPickerCoords(camera: ctx.camera, span: ctx.region.span)
        }
    }
    .simultaneousGesture(longPressHackDragGesture)
    .onReceive(longPressTimer, perform: { time in
        onLongPressTimerFire(proxy: proxy)
    })
    .overlay {
        MapSettingsOverlay(settingsShown: $viewModel.mapSettings.settingsShown,
                           hidePointsOfInterest: $viewModel.mapSettings.hidePointsOfInterest,
                           satellite: $viewModel.mapSettings.satellite)
    }
    .overlay {
        zoomOnUserOverlay
    }
    // Sheets
    .sheet(isPresented: $showingQuickCreateSheet, onDismiss: {
        viewModel.discardCreation()
        // Load the possible created place
        Task {
            await reloadPlaces()
        }
    }, content: {
        viewModel.createPlaceCreateQuickView()
            .presentationDetents([.height(createPlaceSheetDefaultDetent)])
            .presentationBackground(.backgroundPrimary)
    })
    .sheet(item: $viewModel.selectedPlaceId,
           onDismiss: { viewModel.detailSheetDetent = .medium }) { placeId in
        createPlaceDetailsSheetView()
            .presentationDetents([.medium, .large], selection: $viewModel.detailSheetDetent)
            .presentationCornerRadius(20)
            .presentationBackground(.backgroundPrimary)
    }
   .sheetOverlay(isPresented: $viewModel.pickingAddress) {
       AddressPickerView(coords: $viewModel.addressPickerCoords,
                         address: $viewModel.pickedAddress,
                         onFetchAddress: onAddressPickerFetchAddress,
                         onComplete: onAddressPickerComplete)
           .sheetOverlayDetents([.height(viewModel.pickingAddress ? addressSheetHeight : coordinatesSheetHeight)])
           .sheetOverlayDragIndicator(.visible)
   }
}


private func onAddressPickerFetchAddress() {
    guard viewModel.pickedAddress == nil else {
        // Already fetched for this position
        return
    }
    Task {
        do {
            let address = try await viewModel.fetchAddress(coords: viewModel.addressPickerCoords)
            viewModel.pickedAddress = address
        } catch {
            // TODO: handle error
            return
        }
    }
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
        showingQuickCreateSheet.toggle()
    }
}

private func updateAddressPickerCoords() {
    updateAddressPickerCoords(camera: viewModel.mapSettings.currentCamera,
                              span: viewModel.mapSettings.currentRegion.span)
}

private func updateAddressPickerCoords(camera: MapCamera, span: MKCoordinateSpan) {
    let spanLat = span.latitudeDelta
    let lat = camera.centerCoordinate.latitude
    let lon = camera.centerCoordinate.longitude
    
    let sheetHeight = viewModel.pickingAddress ? addressSheetHeight : coordinatesSheetHeight
    let offset: CGFloat = (sheetHeight - DropinApp.ui.mainTabBarHeight) * -0.5
    let latOffset = spanLat * offset / viewModel.dataSource.mapSize.height
    
    // ICI TODO: use map conversion
    
    let targetLat = lat - latOffset + 0.000010
    
    let frmt = CLLocationCoordinate2D(latitude: targetLat,
                                      longitude: lon).formatted()
    //print("LatLon: \(frmt)")
    viewModel.addressPickerCoords = CLLocationCoordinate2D(latitude: targetLat,
                                                           longitude: lon)
}

private var stateObservers: some View {
    EmptyView()
        .onChange(of: places, { _, newValue in
            Task {
                guard viewModel.dataSource.isEmpty() else {
//                        print("UPDATE DATA SOURCE")
//                        await viewModel.updateDataSource(places: newValue)
//                        await viewModel.dataSource.reloadAnnotations()
                    return
                }
                // Only fill data source the first time
                await viewModel.fillDataSource(places: newValue)
            }
        })
        .onChange(of: viewModel.selectedPlaceId) {
            zoomOnPin()
        }
        .onChange(of: viewModel.selectedClusterId, { _, newValue in
            guard let value = newValue else { return }
            zoomOnCluster(value)
            viewModel.selectedClusterId = nil
        })
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
                        viewModel.mapSettings.position = .camera(MapCamera(centerCoordinate: userLoc, distance: 5000))
                    }
                    .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                }
            } else {
                MapIcoButton(systemImage: "exclamationmark.triangle",
                             offset: CGPoint(x: 0, y: -1),
                             imageFrame: CGSize(width: 15, height: 15),
                             color: .warning) {
                    showAuthLocAlert.toggle()
                }
                .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                .alert("common.loc_auth_missing", isPresented: $showAuthLocAlert) {
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
    // Marker is already centered on map, add an offset to get it centered
    // on remaining visible map after presenting sheetOverlay
    let sheetHeight = viewModel.pickingAddress ? addressSheetHeight : coordinatesSheetHeight
    let offset: CGFloat = (sheetHeight - DropinApp.ui.mainTabBarHeight) * -0.5
    let markerSize: CGFloat = 43
    //let gradientColors: [Color] = [.dropinPrimary.opacity(0.45), .dropinPrimary]
    let gradientColors: [Color] = [.init(rgba: "fd6da5"), .init(rgba: "d91235")]
    MapMarkerShape()
        .fill(.white)
        .frame(width: markerSize, height: markerSize)
        .offset(y: offset - markerSize * 0.5)
        .shadow(radius: 5, y: 3)
        .overlay(alignment: .center) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: gradientColors,
                                         startPoint: .top,
                                         endPoint: .bottom))

                    .frame(width: markerSize * 3 / 5,
                           height: markerSize * 3 / 5)
                Image(systemName: "pin")
                    .font(.footnote)
                    .foregroundStyle(.white)
            }
            .offset(y: offset - markerSize * 0.5)
        }
}

// MARK: map contents
@MapContentBuilder
private var mapContent: some MapContent {
    if let _ = viewModel.selectedPlaceId {
        mapContentWithSelection
    } else {
        mapContentWithNoSelection
    }
}

@MapContentBuilder
private var mapContentWithSelection: some MapContent {
    
    placeSmallAnnotations
    
    if let selectedPlaceId = viewModel.selectedPlaceId,
       let selectedPlaceIdx = retrievePlaceIndex(id: selectedPlaceId) {
        Marker(places[selectedPlaceIdx].name,
               systemImage: "mappin.circle",
               coordinate: places[selectedPlaceIdx].coordinates)
    } else {
        assertionInMapContentBuilder("could not find any place with id \(viewModel.selectedPlaceId?.id ?? "none") in mapContentWithSelection")
    }
    
    //clusterAnnotations
}

@MapContentBuilder
private var mapContentWithNoSelection: some MapContent {
    placeAnnotations
    
    // Add a marker at current new temporary place
    if let tmpPlace = viewModel.tmpPlace, tmpPlace.isActive {
        Marker(tmpPlace.name,
               monogram: Text("common.new".uppercased()),
               coordinate: tmpPlace.coordinates)
    }
    
    clusterAnnotations
}

@MapContentBuilder
private var clusterAnnotations: some MapContent {
    ForEach(viewModel.dataSource.clusters) { item in
        
        ClusterAnnotation(cluster: item,
                          selectedClusterId: $viewModel.selectedClusterId)

//            Marker(
//                "\(item.count)",
//                systemImage: "square.3.layers.3d",
//                coordinate: item.coordinate
//            )
    }
}

@MapContentBuilder
private var placeAnnotations: some MapContent {
    ForEach(viewModel.dataSource.annotations) { item in
        if let placeIndex = retrievePlaceIndex(id: item.placeId),
           viewModel.selectedPlaceId != item.placeId {
            PlaceAnnotation(place: $places[placeIndex],
                            selectedPlaceId: $viewModel.selectedPlaceId)
        }
    }
}

private var placeSmallAnnotations: some MapContent {

    // Do not show clusters when displaying small annotations
    // TODO: loop on viewModel.dataSource.annotations + viewModel.dataSource.clusters anyway, so we do not create out pf screen stuf
    ForEach(places.indices, id: \.self) { placeIdx in
        if places[placeIdx].id != viewModel.selectedPlaceId &&
           places[placeIdx].isActive {
            PlaceSmallAnnotation(place: places[placeIdx])
        }
    }

    /*
    ForEach(viewModel.dataSource.annotations) { item in
        if let placeIndex = retrievePlaceIndex(id: item.placeId),
           viewModel.selectedPlaceId != item.placeId {
            PlaceSmallAnnotation(place: places[placeIndex])
        }
    }
     */
}

// MARK: - Gestures
private var longPressHackDragGesture: some Gesture {
    // This is a hack to detect a longPressGesture while being able to have position without overriding map drag gesture
    DragGesture(minimumDistance: 0)
        .onChanged({ gesture in
            if let _ = longPressGestureDateStart {
                if abs(gesture.translation.width) > 1 || abs(gesture.translation.height) > 1 {
                    longPressGestureCanceled = true
                }
            } else {
                if viewModel.mapSettings.settingsShown {
                    viewModel.mapSettings.settingsShown = false
                }
                longPressGestureDateStart = Date.now
                longPressGestureCanceled = false
                longPressGestureLocation = gesture.location
                longPressTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
            }
        })
        .onEnded({ gesture in
            longPressGestureDateStart = nil
            longPressTimer.upstream.connect().cancel()
        })
}

// MARK: - Actions
private func retrievePlaceIndex(id: UUID) -> Int? {
    return places.firstIndex(where: { $0.id == id })
}

private func onFirstAppear() {
    // Disable long press timer, will start when needed
    longPressTimer.upstream.connect().cancel()
    
    // TODO: Improve location at load
    
    // Get user position if defined
    DispatchQueue.main.asyncAfter(deadline: .now()) {
        // NOTE: Randomly crashing at startup if not in async, to be investigated
        guard let currentLoc = viewModel.locationManager.lastKnownLocation else { return }
        viewModel.mapSettings.position = .camera(MapCamera(centerCoordinate: currentLoc,
                                                           distance: 10000))
    }
}

private func onLongPressTimerFire(proxy: MapProxy) {
    // We trigger a long press action after 1sec if the user did not start dragging
    guard let longTapGestureDateStart = longPressGestureDateStart else { return }
    guard !longPressGestureCanceled else {
        print("Long tap cancelled as drag began")
        return
    }
    let longTouchMinDuration: Double = 1
    let delta = Date.now.timeIntervalSince1970 - longTapGestureDateStart.timeIntervalSince1970
    guard delta >= longTouchMinDuration else { return }
    // Get screen coordinates and convert to latlong
    guard let longPressLocation = longPressGestureLocation else {
        fatalError("Long press location undefined")
    }
    let coordinates = proxy.convert(longPressLocation, from: .local)!
    prepareCreatePlaceFromCoords(coordinates)
    // Cancel long press timer
    longPressTimer.upstream.connect().cancel()
}

private func prepareCreatePlaceFromCoords(_ coordinates: CLLocationCoordinate2D) {
    let createdPlace = viewModel.preparePlaceFromCoords(coords: coordinates)
    // Show the creation sheet
    showingQuickCreateSheet.toggle()
    // Center map on new place
    zoomOnPlace(createdPlace)
}

private func updateCameraCache(_ context : MapCameraUpdateContext) {
    /*
    viewModel.mapSettings.currentCameraCenter = context.camera.centerCoordinate
    viewModel.mapSettings.currentCameraDistance = context.camera.distance
    viewModel.mapSettings.currentRegionSpan = context.region.span
     */
    viewModel.mapSettings.currentCamera = context.camera
    viewModel.mapSettings.currentRegion = context.region
    viewModel.mapSettings.currentRect = context.rect
}

private func zoomOnCluster(_ clusterId: UUID) {
    guard let cluster = viewModel.dataSource.clusters.first(where: { $0.id == clusterId }) else {
        return
    }
    let region = MKCoordinateRegion(center: cluster.coordinate,
                                    span: cluster.span)
    withAnimation(.easeInOut(duration: zoomMapDuration)) {
        viewModel.mapSettings.position = .region(region)
    }
}

private func zoomOnPlace(_ place: PlaceUI) {
    let fraction = createPlaceSheetDefaultDetent / UIScreen.main.bounds.size.height
    //let latitudeDeltaOverSheet = viewModel.mapSettings.currentRegionSpan.latitudeDelta * (1 - createPlaceSheetDefaultDetent)
    let latitudeDeltaOverSheet = viewModel.mapSettings.currentRegion.span.latitudeDelta * (1 - fraction)
    let offset = viewModel.mapSettings.currentRegion.span.latitudeDelta * 0.5 - latitudeDeltaOverSheet * 0.5
    // Offset the new place coords so it's visible on the map despite the sheet appearing
    let coords = CLLocationCoordinate2D(latitude: place.coordinates.latitude - offset,
                                        longitude: place.coordinates.longitude)
    withAnimation(.easeInOut(duration: zoomMapDuration)) {
        viewModel.mapSettings.position = .camera(MapCamera(centerCoordinate: coords,
                                                           distance: viewModel.mapSettings.currentCamera.distance))
    }
}

private func zoomOnPin() {
    guard let selectedPlaceId = viewModel.selectedPlaceId else {
        return
    }
    guard let place = places.first(where: { $0.id == selectedPlaceId }) else {
        return
    }
    //guard let place = viewModel.pinPlace else { return  }
    zoomOnPlace(place)
}

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

/* Obsolete
private func createPlaceDetailsSheetView() -> PlaceDetailsSheetView {
    guard let placeId = viewModel.selectedPlaceId else {
        fatalError("selectedPlaceId undefined")
    }
    guard let index = places.firstIndex(where: { $0.id == placeId.id }) else {
        fatalError("couldn't find place with id \(placeId)")
    }
    return viewModel.createPlaceDetailsSheetView(place: $places[index])
}
*/

private func reloadPlaces() async {
    do {
        places = try await viewModel.loadPlaces()
        await viewModel.updateDataSource(places: places)
        await viewModel.dataSource.reloadAnnotations()
    } catch {
        assertionFailure("couldn't reload places")
    }
}

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
}

#endif
