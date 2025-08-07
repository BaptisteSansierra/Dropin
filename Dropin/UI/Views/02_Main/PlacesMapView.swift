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

    @Environment(LocationManager.self) private var locationManager
    @Environment(PlaceFactory.self) private var placeFactory
    @Environment(MapSettings.self) private var mapSettings
    @Environment(AppNavigationContext.self) private var navigationContext

    @Query var places: [SDPlace]
    
    @State private var showingLongPressCreateSheet = false
    @State private var showAuthLocAlert = false
    // Long press behaviour
    @State private var longPressGestureDateStart: Date?
    @State private var longPressGestureCanceled = false
    @State private var longPressGestureLocation: CGPoint?
    @State private var longPressTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        
        @Bindable var mapSettings = mapSettings
        //@Bindable var selectedPin = navigationContext.preSelectedPlace
        @Bindable var navigationContext = navigationContext

        NavigationStack {
            
            MapReader { proxy in
                
                
                // TODO:  have a list of PlaceAnnotation + Marker
                // with 2 ForEach so we get rid of the IF
                
                Map(position: $mapSettings.position) {
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
                // This is a hack to detect a longPressGesture while being able to have position without overriding map drag gesture
                .simultaneousGesture(DragGesture(minimumDistance: 0)
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
                        }))
                .onReceive(longPressTimer, perform: { time in
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
                    longPressTimer.upstream.connect().cancel()
                })
                .animation(.easeInOut, value: mapSettings.position)
                .mapControls {
                    MapCompass()
                }
                .mapStyle(mapSettings.selectedMapStyle)
                .selectionDisabled(false)
                .onMapCameraChange(frequency: .onEnd) { mapCameraUpdateContext in
                    mapSettings.currentCenter = mapCameraUpdateContext.region.center
                }
                .onFirstAppear {
                    // Disable long press timer, will start when needed
                    longPressTimer.upstream.connect().cancel()
                    // Get user position if defined
                    guard let currentLoc = locationManager.lastKnownLocation else { return }
                    mapSettings.position = MapCameraPosition.region(
                        MKCoordinateRegion(
                            center: currentLoc,
                            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
                        )
                    )
                }
                .overlay {
                    MapSettingsOverlay()
                        .environment(mapSettings)
                }
                .overlay {
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
                .sheet(isPresented: $showingLongPressCreateSheet, onDismiss: {
                    placeFactory.reset()
                }, content: {
                    CreatePlaceView()
                })
                .sheet(item: $navigationContext.pinPlace) { place in
                    Text("SELECTED: \(place.name)")
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
                BurgerToolbar()
                LogoToolbar()
                AddPlaceToolbar()
            }
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    HStack {
//                        Button("Add", systemImage: "plus") {
//                            navigationContext.showingCreatePlaceMenu.toggle()
//                        }
//                        .tint(.dropinPrimary)
//                    }
//                }
//            }
            .navigationDestination(for: SDPlace.self) { place in
                PlaceDetails()
                    .environment(place)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
