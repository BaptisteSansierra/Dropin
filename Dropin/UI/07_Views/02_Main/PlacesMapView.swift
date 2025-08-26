//
//  PlacesMapView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/7/25.
//

import SwiftUI
import SwiftData
import CoreLocation
import MapKit
import Combine
 
struct PlacesMapView: View {

    // MARK: - State & Bindings
    @State private var showingLongPressCreateSheet = false
    @State private var showAuthLocAlert = false
    // Long press behaviour
    @State private var longPressGestureDateStart: Date?
    @State private var longPressGestureCanceled = false
    @State private var longPressGestureLocation: CGPoint?
    @State private var longPressTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    // DB
    @Query var places: [SDPlace]

    // MARK: - Dependencies
    @Environment(LocationManager.self) private var locationManager
    @Environment(PlaceFactory.self) private var placeFactory
    @Environment(MapSettings.self) private var mapSettings
    @Environment(NavigationContext.self) private var navigationContext

    // MARK: - private var
    private var createPlaceSheetDefaultDetent: CGFloat = 0.6

    // MARK: - Body
    var body: some View {
        // Bindable
        @Bindable var mapSettings = mapSettings
        @Bindable var navigationContext = navigationContext

        // Content
        NavigationStack(path: $navigationContext.navigationPath) {
            MapReader { proxy in
                
                Map(position: $mapSettings.position) {
                    
                    // Add a marker at current new temporary place
                    if placeFactory.buildingPlace {
                        Marker(placeFactory.place.name,
                               monogram: Text("NEW"),
                               coordinate: placeFactory.place.coordinates)
                    }

                    
                    // TODO:  have a list of PlaceAnnotation + Marker
                    // with 2 ForEach so we get rid of the IF_ELSE
                    
                    if let selectedPlace = navigationContext.pinPlace {
                        ForEach(places) { place in
                            if selectedPlace.name == place.name {
                                Marker(selectedPlace.name, coordinate: selectedPlace.coordinates)
                            } else {
                                PlaceAnnotation(place: place)
                            }
                        }
                    } else {
                        ForEach(places) { place in
                            PlaceAnnotation(place: place)
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
                    placeFactory.discard()
                }, content: {
                    CreatePlaceView()
                        //.presentationDetents([.medium, .large])
                        .presentationDetents([.fraction(createPlaceSheetDefaultDetent), .large])
                })
                .onChange(of: navigationContext.pinPlace) {
                    guard let place = navigationContext.pinPlace else { return  }
                    zoomOnPlace(Place(sdPlace: place))
                }
                .sheet(item: $navigationContext.pinPlace) { sdPlace in
                    PlaceDetailsSheetView(place: Place(sdPlace: sdPlace))
                        .presentationDetents([.medium, .large])
                        .presentationCornerRadius(20)
                }
                .alert("Location Access not authorized", isPresented: $showAuthLocAlert) {
                    Button("Open Settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                    Button("Cancel") {}
                } message: {
                    Text("This app requires location access to function properly.\nPlease enable location permissions in Settings.")
                }
            }
            .toolbar {
                DropinToolbar.Burger()
                DropinToolbar.Logo()
                DropinToolbar.AddPlace()
            }
            .navigationDestination(for: SDPlace.self) { place in
                PlaceDetailsView(place: Place(sdPlace: place), editMode: .edit)
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
        placeFactory.prepareFromCoords(coords: coordinates)
        // Show the creation sheet
        showingLongPressCreateSheet.toggle()
        // Center map on new place
        zoomOnPlace(placeFactory.place)
        // Cancel long press timer
        longPressTimer.upstream.connect().cancel()
    }
    
    private func updateCameraCache(_ context : MapCameraUpdateContext) {
        mapSettings.currentCameraCenter = context.camera.centerCoordinate
        mapSettings.currentCameraDistance = context.camera.distance
        mapSettings.currentRegionSpan = context.region.span
    }
    
    private func zoomOnPlace(_ place: Place) {
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
}
