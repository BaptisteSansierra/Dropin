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
    @State private var showingLongPressCreateSheet = false
    @State private var showAuthLocAlert = false
    // Long press behaviour
    @State private var longPressGestureDateStart: Date?
    @State private var longPressGestureCanceled = false
    @State private var longPressGestureLocation: CGPoint?
    @State private var longPressTimer = Timer.publish(every: 100, on: .main, in: .common).autoconnect()

    // MARK: - Dependencies
    @Environment(LocationManager.self) private var locationManager
    @Environment(MapSettings.self) private var mapSettings
    @Environment(NavigationContext.self) private var navigationContext

    // MARK: - private var
    private let zoomMapDuration: TimeInterval = 10
    private var createPlaceSheetDefaultDetent: CGFloat = 0.6

    // MARK: - Init
    init(viewModel: PlacesMapViewModel, places: Binding<[PlaceUI]>) {
        self.viewModel = viewModel
        self._places = places
    }

    // MARK: - Body
    var body: some View {
        // Bindable
        @Bindable var viewModel = viewModel
        @Bindable var mapSettings = mapSettings
        @Bindable var navigationContext = navigationContext

        NavigationStack(path: $navigationContext.navigationPath) {
            MapReader { proxy in
                Map(position: $mapSettings.position) {
                    
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
                .mapStyle(mapSettings.selectedMapStyle)
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
                    MapSettingsOverlay()
                        .environment(mapSettings)
                }
                .overlay {
                    zoomOnUserOverlay
                }
                .sheet(isPresented: $showingLongPressCreateSheet, onDismiss: {
                    viewModel.discardCreation()
                    Task {
                        places = try await viewModel.loadPlaces()
                        reloadData()
                    }
                }, content: {
                    viewModel.createCreatePlacesView()
                    //.presentationDetents([.medium, .large])
                        .presentationDetents([.fraction(createPlaceSheetDefaultDetent), .large])
                })
                .onChange(of: viewModel.selectedPlaceId) {
                    zoomOnPin()
                }
                .sheet(item: $viewModel.selectedPlaceId) { placeId in
                    createPlaceDetailsSheetView()
                        .presentationDetents([.medium, .large])
                        .presentationCornerRadius(20)
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
            .safeAreaInset(edge: .bottom, content: {
                Color.clear
                    .frame(height: 40)
            })
            .navigationDestination(for: PlaceEntity.self) { place in
                createPlaceDetailsView(place)
            }
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                DropinToolbar.Burger()
                DropinToolbar.Logo()
                DropinToolbar.AddPlace()
            }
        }
//        .customToolbar(tabIndex: 0,
//                       leading: {
//                           BurgerToolbarView()
//                       }, trailing: {
//                           AddPlaceToolbarView()
//                       }, title: {
//                           LogoToolbarView()
//                       })

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

    // MARK: - Subviews
    private var zoomOnUserOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if let locauthorized = locationManager.authorized, locauthorized {
                    if let userLoc = locationManager.lastKnownLocation {
                        MapIcoButton(systemImage: "location.fill", offset: CGPoint(x: -1, y: 1), imageFrame: CGSize(width: 15, height: 15))
                            .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                            .onTapGesture {
                                mapSettings.position = .camera(MapCamera(centerCoordinate: userLoc, distance: 5000))
                            }
                    }
                } else {
                    MapIcoButton(systemImage: "exclamationmark.triangle", offset: CGPoint(x: 0, y: -1), imageFrame: CGSize(width: 15, height: 15), color: .red)
                        .padding(EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10))
                        .onTapGesture {
                            showAuthLocAlert.toggle()
                        }
                }
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
                    if mapSettings.settingsShown {
                        mapSettings.settingsShown = false
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
            guard let currentLoc = locationManager.lastKnownLocation else { return }
            self.mapSettings.position = .camera(MapCamera(centerCoordinate: currentLoc, distance: 10000))
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
        mapSettings.currentCameraCenter = context.camera.centerCoordinate
        mapSettings.currentCameraDistance = context.camera.distance
        mapSettings.currentRegionSpan = context.region.span
        // Enable clustering if camera is far enough
        viewModel.clusteringEnabled = mapSettings.currentCameraDistance > 1000
        
        print("Current zoom = \(mapSettings.currentCameraDistance)")
        
        // Compute places under camera
        reloadData()
    }
    
    private func zoomOnCluster(_ cluster: MapDisplayClusterItem) {
        let region = MKCoordinateRegion(center: cluster.center,
                                        span: cluster.span)
        withAnimation(.easeInOut(duration: zoomMapDuration)) {
            mapSettings.position = .region(region)
        }
    }
    
    private func zoomOnPlace(_ place: PlaceUI) {
        let latitudeDeltaOverSheet = mapSettings.currentRegionSpan.latitudeDelta * (1 - createPlaceSheetDefaultDetent)
        let offset = mapSettings.currentRegionSpan.latitudeDelta * 0.5 - latitudeDeltaOverSheet * 0.5
        // Offset the new place coords so it's visible on the map despite the sheet appearing
        let coords = CLLocationCoordinate2D(latitude: place.coordinates.latitude - offset,
                                            longitude: place.coordinates.longitude)
        withAnimation(.easeInOut(duration: zoomMapDuration)) {
            mapSettings.position = .camera(MapCamera(centerCoordinate: coords,
                                                     distance: mapSettings.currentCameraDistance))
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

    private func createPlaceDetailsSheetView() -> PlaceDetailsSheetView {
        guard let placeId = viewModel.selectedPlaceId else {
            fatalError("selectedPlaceId undefined")
        }
        guard let index = places.firstIndex(where: { $0.id == placeId.id }) else {
            fatalError("couldn't find place with id \(placeId)")
        }
        return viewModel.createPlaceDetailsSheetView(place: $places[index])
    }

    private func reloadData() {
        viewModel.gridBasedClustering(places,
                                      center: mapSettings.currentCameraCenter,
                                      span: mapSettings.currentRegionSpan)
    }
        
    private func createPlaceDetailsView(_ place: PlaceEntity) -> PlaceDetailsView {
        guard let index = places.firstIndex(where: { $0.id == place.id }) else {
            fatalError("couldn't find any place named '\(place.name)' in list")
        }
        return viewModel.createPlaceDetailsView(place: $places[index], editMode: .none)
    }
}

#if DEBUG
struct MockPlacesMapView: View {
    var mock: MockContainer
    @State var places: [PlaceUI]

    var body: some View {
        mock.appContainer.createPlacesMapView(places: $places)
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
            .environment(LocationManager())
            .environment(MapSettings())
            .environment(NavigationContext())
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#endif
