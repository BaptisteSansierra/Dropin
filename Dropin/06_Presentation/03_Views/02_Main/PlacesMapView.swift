//
//  PlacesMapView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI
import CoreLocation
import MapKit


struct PlacesMapView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: PlacesMapViewModel
    @Binding private var places: [PlaceUI]
    @Binding private var showingCreatePlaceMenu: Bool
    // TODO: move states to view model
    @State private var showingLongPressCreateSheet = false
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
        mapReaderView
            .onAppear {
                onAppearCallback()
            }
    }

    // MARK: - Subviews
    private var mapReaderView: some View {
        return MapReader { proxy in
            mapView(proxy: proxy)
        }
        .safeAreaInset(edge: .bottom, content: {
            Color.clear
                .frame(height: 40)
        })
        .confirmationDialog("common.save_new_place",
                            isPresented: $showingCreatePlaceMenu,
                            titleVisibility: .visible,
                            actions: createNewPlaceActions)
        .presentationCompactAdaptation(.sheet)
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
        return Map(position: $viewModel.mapSettings.position) {
            mapContent
            UserAnnotation()
        }
        .simultaneousGesture(longPressHackDragGesture)
        .onReceive(longPressTimer, perform: { time in
            onLongPressTimerFire(proxy: proxy)
        })
        .onChange(of: viewModel.selectedCluster, { oldValue, newValue in
            guard let value = newValue else { return }
            zoomOnCluster(value)
            viewModel.selectedCluster = nil
        })
        //.animation(.easeInOut(duration: zoomMapDuration), value: mapSettings.position)
        .mapControls {
            MapCompass()
        }
        .mapStyle(viewModel.mapSettings.selectedMapStyle)
        .selectionDisabled(false)
        .onMapCameraChange(frequency: .continuous) { _ in
            // Cancel long press timer when moving map camera
            longPressTimer.upstream.connect().cancel()
        }
        .onMapCameraChange(frequency: .onEnd) { mapCameraUpdateContext in
            updateCameraCache(mapCameraUpdateContext)
        }
        .task {
            onFirstAppear()
        }
        .overlay {
            MapSettingsOverlay(settingsShown: $viewModel.mapSettings.settingsShown,
                               hidePointsOfInterest: $viewModel.mapSettings.hidePointsOfInterest,
                               satellite: $viewModel.mapSettings.satellite)
        }
        .overlay {
            zoomOnUserOverlay
        }
        .sheet(isPresented: $showingLongPressCreateSheet, onDismiss: {
            viewModel.discardCreation()
            // Load the possible created place
            Task {
                await reloadPlaces()
            }
        }, content: {
            viewModel.createCreatePlacesView()
                //.presentationDetents([.fraction(createPlaceSheetDefaultDetent), .large])
                .presentationDetents([.height(createPlaceSheetDefaultDetent)])
                .presentationBackground(.backgroundPrimary)
        })
        .onChange(of: viewModel.selectedPlaceId) {
            zoomOnPin()
        }
        .sheet(item: $viewModel.selectedPlaceId) { placeId in
            createPlaceDetailsSheetView()
                .presentationDetents([.medium, .large], selection: $viewModel.detailSheetDetent)
                .presentationCornerRadius(20)
                .presentationBackground(.backgroundPrimary)
        }
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
                }
            }
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
        
        visibleSmallAnnotations
        
        if let selectedPlaceId = viewModel.selectedPlaceId,
           let selectedPlace = places.first(where: { $0.id == selectedPlaceId.id }) {
            Marker(selectedPlace.name,
                   systemImage: "mappin.circle",
                   coordinate: selectedPlace.coordinates)
        } else {
            assertionInMapContentBuilder("could not find any place with id \(viewModel.selectedPlaceId?.id ?? "none") in mapContentWithSelection")
        }
    }
    
    @MapContentBuilder
    private var mapContentWithNoSelection: some MapContent {
        if viewModel.clusteringEnabled {
            clusteredAnnotations
#if DEBUG
            if viewModel.debugDisplayBuckets {
                bucketsPolygons
            }
#endif
        } else {
            visibleAnnotations
        }
        
        // Add a marker at current new temporary place
        if let tmpPlace = viewModel.tmpPlace, !tmpPlace.databaseDeleted {
            Marker(tmpPlace.name,
                   monogram: Text("common.new".uppercased()),
                   coordinate: tmpPlace.coordinates)
        }
    }
    
    private var visibleAnnotations: some MapContent {
        ForEach(viewModel.visiblePlaces) { place in
            if viewModel.selectedPlaceId == nil ||
               viewModel.selectedPlaceId?.id != place.id {
                PlaceAnnotation(place: place,
                                selectedPlaceId: $viewModel.selectedPlaceId)
            }
        }
    }

    private var visibleSmallAnnotations: some MapContent {
        ForEach(viewModel.visiblePlaces) { place in
            if viewModel.selectedPlaceId == nil ||
               viewModel.selectedPlaceId?.id != place.id {
                PlaceSmallAnnotation(place: place)
            }
        }
    }
    
#if DEBUG
    private var bucketsPolygons: some MapContent {
        ForEach(viewModel.buckets, id: \.self.id) { bucket in
            let p1 = bucket.origin
            let p2 = CLLocationCoordinate2D(latitude: p1.latitude + bucket.span.latitudeDelta,
                                            longitude: p1.longitude)
            let p3 = CLLocationCoordinate2D(latitude: p1.latitude + bucket.span.latitudeDelta,
                                            longitude: p1.longitude + bucket.span.longitudeDelta)
            let p4 = CLLocationCoordinate2D(latitude: p1.latitude,
                                            longitude: p1.longitude + bucket.span.longitudeDelta)
            MapPolygon(coordinates: [p1, p2, p3, p4, p1])
                .foregroundStyle(.clear)
                .stroke(.orange, lineWidth: 1)
        }
    }
#endif
    
    private var clusteredAnnotations: some MapContent {
        ForEach(viewModel.mapItems) { mapItem in
            if let placeMapItem = mapItem as? MapDisplayPlaceItem {
                if viewModel.selectedPlaceId == nil ||
                    viewModel.selectedPlaceId?.id != placeMapItem.place.id {
                    PlaceAnnotation(item: placeMapItem,
                                    selectedPlaceId: $viewModel.selectedPlaceId)
                }
            } else if let clusterMapItem = mapItem as? MapDisplayClusterItem {
                ClusterAnnotation(clusterItem: clusterMapItem,
                                  selectedCluster: $viewModel.selectedCluster)
            }
        }
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
    private func onFirstAppear() {
        // Disable long press timer, will start when needed
        longPressTimer.upstream.connect().cancel()
        
        
        // TODO: Improve location at load
        
        // Get user position if defined
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            // NOTE: Randomly crashing at startup if not in async, to be investigated
            guard let currentLoc = viewModel.locationManager.lastKnownLocation else { return }
            viewModel.mapSettings.position = .camera(MapCamera(centerCoordinate: currentLoc, distance: 10000))
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
        let createdPlace = viewModel.preparePlaceFromCoords(coords: coordinates)
        // Show the creation sheet
        showingLongPressCreateSheet.toggle()
        // Center map on new place
        zoomOnPlace(createdPlace)
        // Cancel long press timer
        longPressTimer.upstream.connect().cancel()
    }
    
    private func updateCameraCache(_ context : MapCameraUpdateContext) {
        viewModel.mapSettings.currentCameraCenter = context.camera.centerCoordinate
        viewModel.mapSettings.currentCameraDistance = context.camera.distance
        viewModel.mapSettings.currentRegionSpan = context.region.span
        // Enable clustering if camera is far enough
        viewModel.clusteringEnabled = viewModel.mapSettings.currentCameraDistance > 1000
        
        //print("Current zoom = \(mapSettings.currentCameraDistance)")
        
        // Compute places under camera
        updateClustering()
    }
    
    private func zoomOnCluster(_ cluster: MapDisplayClusterItem) {
        let region = MKCoordinateRegion(center: cluster.center,
                                        span: cluster.span)
        withAnimation(.easeInOut(duration: zoomMapDuration)) {
            viewModel.mapSettings.position = .region(region)
        }
    }
    
    private func zoomOnPlace(_ place: PlaceUI) {
        let fraction = createPlaceSheetDefaultDetent / UIScreen.main.bounds.size.height
        //let latitudeDeltaOverSheet = viewModel.mapSettings.currentRegionSpan.latitudeDelta * (1 - createPlaceSheetDefaultDetent)
        let latitudeDeltaOverSheet = viewModel.mapSettings.currentRegionSpan.latitudeDelta * (1 - fraction)
        let offset = viewModel.mapSettings.currentRegionSpan.latitudeDelta * 0.5 - latitudeDeltaOverSheet * 0.5
        // Offset the new place coords so it's visible on the map despite the sheet appearing
        let coords = CLLocationCoordinate2D(latitude: place.coordinates.latitude - offset,
                                            longitude: place.coordinates.longitude)
        withAnimation(.easeInOut(duration: zoomMapDuration)) {
            viewModel.mapSettings.position = .camera(MapCamera(centerCoordinate: coords,
                                                               distance: viewModel.mapSettings.currentCameraDistance))
        }
    }
    
    private func zoomOnPin() {
        guard let placeId = viewModel.selectedPlaceId else {
            return
        }
        guard let place = places.first(where: { $0.id == placeId.id }) else {
            return
        }
        //guard let place = viewModel.pinPlace else { return  }
        zoomOnPlace(place)
    }

    private func createPlaceDetailsSheetView() -> PlaceSheetView {
        guard let placeId = viewModel.selectedPlaceId else {
            fatalError("selectedPlaceId undefined")
        }
        guard let index = places.firstIndex(where: { $0.id == placeId.id }) else {
            fatalError("couldn't find place with id \(placeId)")
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
            updateClustering()
        } catch {
            assertionFailure("couldn't reload places")
        }
    }

    private func updateClustering() {
        viewModel.gridBasedClustering(places,
                                      center: viewModel.mapSettings.currentCameraCenter,
                                      span: viewModel.mapSettings.currentRegionSpan)
    }
    
    private func onAppearCallback() {
        guard let lastNavigationSource = viewModel.coordinator.lastNavigationSource else {
            print("Navigation history EMPTY")
            return
        }
        switch lastNavigationSource {
            case .createPlaceFullView:
                Task {
                    await reloadPlaces()
                }
            default:
                ()
        }

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
