//
//  PlacesMapView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI
//import SwiftData
import CoreLocation
import MapKit
//import Combine
 
struct PlacesMapView: View {
    
    // MARK: - Properties
    private var viewModel: PlacesMapViewModel

    // MARK: - State & Bindings
    @State private var showingLongPressCreateSheet = false
    @State private var showAuthLocAlert = false
    // Long press behaviour
    @State private var longPressGestureDateStart: Date?
    @State private var longPressGestureCanceled = false
    @State private var longPressGestureLocation: CGPoint?
    @State private var longPressTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    // MARK: - Dependencies
    @Environment(LocationManager.self) private var locationManager
    @Environment(MapSettings.self) private var mapSettings
    @Environment(NavigationContext.self) private var navigationContext

    // MARK: - private var
    private var createPlaceSheetDefaultDetent: CGFloat = 0.6

    // MARK: - Init
    init(viewModel: PlacesMapViewModel) {
        self.viewModel = viewModel
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
                    // Add a marker at current new temporary place
                    if let tmpPlace = viewModel.tmpPlace, !tmpPlace.databaseDeleted {
                        Marker(tmpPlace.name,
                               monogram: Text("common.new".uppercased()),
                               coordinate: tmpPlace.coordinates)
                    }
                    
                    // TODO:  have a list of PlaceAnnotation + Marker
                    // with 2 ForEach so we get rid of the IF_ELSE
                                        
                    if let selectedPlaceId = viewModel.selectedPlaceId {
                        ForEach(viewModel.places) { place in
                            if place.id == selectedPlaceId.id && !place.databaseDeleted {
                                // TODO: this marker should be displayed last to avoid overlay
                                Marker(place.name, coordinate: place.coordinates)
                            } else {
                                if !place.databaseDeleted {
                                    PlaceAnnotation(place: place, selectedPlaceId: $viewModel.selectedPlaceId)
                                }
                            }
                        }
                    } else {
                        ForEach(viewModel.places) { place in
                            if !place.databaseDeleted {
                                PlaceAnnotation(place: place, selectedPlaceId: $viewModel.selectedPlaceId)
                            }
                        }
                    }
                    //.mapItemDetailSelectionAccessory(.callout)
                    UserAnnotation()
                }
                .simultaneousGesture(longPressHackDragGesture)
                .onReceive(longPressTimer, perform: { time in
                    onLongPressTimerFire(proxy: proxy)
                })
                .animation(.easeInOut, value: mapSettings.position)
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
                .onFirstAppear {
                    // TODO: replace by task
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
                        try await viewModel.loadPlaces()
                    }
                }, content: {
                    viewModel.createCreatePlacesView()
                        //.presentationDetents([.medium, .large])
                        .presentationDetents([.fraction(createPlaceSheetDefaultDetent), .large])
                })
                .onChange(of: viewModel.selectedPlaceId) {
                    zoomOnPin()
                }
                /*
                .sheet(isPresented: .constant(viewModel.selectedPlaceId != nil),
                       onDismiss: {
                    viewModel.selectedPlaceId = nil
                }) {
                    createPlaceDetailsSheetView()
                        .presentationDetents([.medium, .large])
                        .presentationCornerRadius(20)
                }
                 */
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
            .toolbar {
                DropinToolbar.Burger()
                DropinToolbar.Logo()
                DropinToolbar.AddPlace()
            }
            .navigationDestination(for: PlaceEntity.self) { place in
                createPlaceDetailsView(place)
            }
            .task {
                Task {
                    try await viewModel.loadPlaces()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
    }
    
    private func zoomOnPlace(_ place: PlaceUI) {
        let latitudeDeltaOverSheet = mapSettings.currentRegionSpan.latitudeDelta * (1 - createPlaceSheetDefaultDetent)
        let offset = mapSettings.currentRegionSpan.latitudeDelta * 0.5 - latitudeDeltaOverSheet * 0.5
        // Offset the new place coords so it's visible on the map despite the sheet appearing
        let coords = CLLocationCoordinate2D(latitude: place.coordinates.latitude - offset,
                                            longitude: place.coordinates.longitude)
        withAnimation(.linear(duration: 0.5)) {
            mapSettings.position = .camera(MapCamera(centerCoordinate: coords,
                                                     distance: mapSettings.currentCameraDistance))
        }
    }
    
    private func zoomOnPin() {
        guard let placeId = viewModel.selectedPlaceId else {
            return
        }
        guard let place = viewModel.places.first(where: { $0.id == placeId.id }) else {
            return
        }
        //guard let place = viewModel.pinPlace else { return  }
        zoomOnPlace(place)
    }
    
    private func createPlaceDetailsView(_ place: PlaceEntity) -> PlaceDetailsView {
        guard let index = viewModel.places.firstIndex(where: { $0.id == place.id }) else {
            fatalError("couldn't find any place named '\(place.name)' in list")
        }
        @Bindable var viewModel = viewModel
        return viewModel.createPlaceDetailsView(place: $viewModel.places[index], editMode: .edit)
    }
    
    private func createPlaceDetailsSheetView() -> PlaceDetailsSheetView {
        guard let placeId = viewModel.selectedPlaceId else {
            fatalError("selectedPlaceId undefined")
        }
        guard let index = viewModel.places.firstIndex(where: { $0.id == placeId.id }) else {
            fatalError("couldn't find place with id \(placeId)")
        }
        @Bindable var viewModel = viewModel
        return viewModel.createPlaceDetailsSheetView(place: $viewModel.places[index])
    }

}

/*
#if DEBUG
#Preview {
    AppContainer.mock().createPlacesMapView()
        .environment(LocationManager())
        .environment(MapSettings())
        .environment(NavigationContext())
}
#endif
*/
