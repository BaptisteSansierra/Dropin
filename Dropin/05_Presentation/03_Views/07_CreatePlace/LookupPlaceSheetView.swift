//
//  LookupPlaceSheetView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/10/26.
//

import SwiftUI
import MapKit

struct LookupPlaceSheetView: View {
    
    enum PresentationStatus: Equatable {
        case cancelled
        case validated(item: LookupResolvedItem)
        case pending
        
        static func == (lhs: PresentationStatus, rhs: PresentationStatus) -> Bool {
            switch (lhs, rhs) {
                case (.cancelled, .cancelled):
                    return true
                case (.validated, .validated):
                    return true
                case (.pending, .pending):
                    return true
                default:
                    return false
            }
        }
    }
    
    // MARK: - States & Bindings
    @Binding private var status: PresentationStatus
    @Binding private var editedPlace: PlaceUIModel?
    @Environment(\.dismiss) private var dismiss
    @State private var camera: MapCameraPosition = .automatic
    @State private var cameraDistance: Double = 1000

    var lookupResolvedItem: LookupResolvedItem
    
    // MARK: - init
    init(lookupResolvedItem: LookupResolvedItem,
         place: Binding<PlaceUIModel?>,
         status: Binding<PresentationStatus>) {
        self.lookupResolvedItem = lookupResolvedItem
        self._editedPlace = place
        self._status = status
    }
    
    // MARK: - body
    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.top, 25)
            mapView
                .padding(.top, 10)
            HStack(alignment: .top, spacing: 0) {
                Text(lookupResolvedItem.address)
                    .textStyle(.cellSubtitle)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                Spacer()
                if let distance = lookupResolvedItem.distance {
                    Text(distance)
                        .textStyle(.cellDetail)
                }
            }
            .padding(.top, 10)
            Spacer()
            actionView
        }
        .padding(.horizontal)
        .onAppear {
            // Set pending status when view appears
            status = .pending
            // Define map camera
            updateCamera()
        }
    }
    
    // MARK: - subviews
    private var headerView: some View {
        HStack(alignment: .center, spacing: 0) {
            headerIconView
                .padding(.trailing)
            VStack(spacing: 0) {
                if let place = editedPlace, !place.name.isEmpty {
                    Text(place.name)
                        .textStyle(.cellTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    textResolvingName(for: lookupResolvedItem)
                        .textStyle(.cellTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let n = lookupResolvedItem.mapItem.pointOfInterestCategory?.displayName {
                    Text(n)
                        .textStyle(.cellSubtitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("common.address")
                        .textStyle(.cellSubtitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer()
            CloseButton { cancel() }
        }
    }
    
    private var headerIconView: some View {
        ZStack {
            if let poi = lookupResolvedItem.mapItem.pointOfInterestCategory {
                RoundedRectangle(cornerRadius: 8)
                    .fill(poi.tint ?? .dropinPrimary)
                    .frame(width: 45, height: 45)
                IconView(icon: poi.icon)
                    .sizeCallout()
                    .foregroundStyle(.surface1)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.backgroundPrimary)
                    .frame(width: 45, height: 45)
                Image(systemName: "mappin")
                    .font(.footnote)
                    .foregroundStyle(.textTertiary)
            }
        }
    }
    
    private var mapView: some View {
        Map(position: $camera,
            interactionModes: [.zoom]) {
            if let place = editedPlace, !place.name.isEmpty {
                // Show custom marker when editing an existing place
                PlaceAnnotation(place: Binding(
                    get: { relocatedPlace(place, lookupResolvedItem) },
                    set: { _ in })
                )
            } else {
                markerResolvingName(for: lookupResolvedItem)
            }
            UserAnnotation()
        }
        .overlay {
            HStack {
                Spacer()
                VStack(spacing: 0){
                    Spacer()
                    MapIcoButton(systemImage: "plus",
                                 color: cameraDistance < 125 ? .disabled : .dropinPrimary,
                                 action: { zoomIn() })
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 15, trailing: 10))
                    MapIcoButton(systemImage: "minus",
                                 color: cameraDistance >= 32_768_000 ? .disabled : .dropinPrimary,
                                 action: { zoomOut() })
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 15, trailing: 10))
                }
            }
        }
        .frame(height: 220)
        .cornerRadius(15)
    }
    
    private var actionView: some View {
        MainButton(text: lookupResolvedItem.isPOI ? "lookup.action.place" : "lookup.action.address",
                   systemImage: "checkmark") {
            confirm()
        }
    }
    
    // MARK: - private methods
    private func textResolvingName(for item: LookupResolvedItem) -> Text {
        if item.isPOI {
            if let name = item.mapItem.name {
                return Text(verbatim: name)
            } else {
                assertionFailure("undefined name for POI")
                return Text("common.new_place")
            }
        } else {
            if let name = item.mapItem.name {
                return Text(verbatim: name)
            } else {
                return Text("common.new_place")
            }
        }
    }
    
    private func relocatedPlace(_ place: PlaceUIModel,
                                _ lookupResolvedItem: LookupResolvedItem) -> PlaceUIModel {
        let relocated = place.copy()
        relocated.coordinates = lookupResolvedItem.coordinates
        return relocated
    }
    
    private func markerResolvingName(for item: LookupResolvedItem) -> some MapContent {
        if item.isPOI {
            if let name = item.mapItem.name {
                return Marker(name,
                              systemImage: item.mapItem.icon().name,
                              coordinate: item.coordinates)
            } else {
                assertionFailure("undefined name for POI")
                return Marker("common.new_place",
                              systemImage: item.mapItem.icon().name,
                              coordinate: item.coordinates)
            }
        } else {
            return Marker("common.new_place",
                          systemImage: item.mapItem.icon().name,
                          coordinate: item.coordinates)
        }
    }
    
    private func zoomIn() {
        guard cameraDistance >= 125 else { return }
        cameraDistance /= 2
        updateCamera()
    }
    
    private func zoomOut() {
        guard cameraDistance < 32_768_000 else { return }
        cameraDistance *= 2
        updateCamera()
    }

    private func updateCamera() {
        let c = lookupResolvedItem.mapItem.resolvedCoordinates()
        camera = .camera(MapCamera(centerCoordinate: c,
                                   distance: cameraDistance))
    }
    
    private func confirm() {
        status = .validated(item: lookupResolvedItem)
        dismiss()
    }
    
    private func cancel() {
        status = .cancelled
        dismiss()
    }
}

#if DEBUG

import MapKit

struct MockLookupPlaceSheetView: View {
    var mock: MockContainer
    @State private var results: [LookupResult] = []
    @State private var lookupResolvedItemPOI: LookupResolvedItem?
    @State private var lookupResolvedItemADR: LookupResolvedItem?
    @State private var lookupError: Error?
    @State private var status: LookupPlaceSheetView.PresentationStatus = .pending
    @State private var place: PlaceUIModel? = nil

    @State private var isPOISheet = false
    @State private var isAddressSheet = false

    var body: some View {
        VStack {
            if let error = lookupError {
                VStack {
                    Text(verbatim: "Error")
                    Text(error.localizedDescription)
                }
            } else if let _ = lookupResolvedItemPOI, let _ = lookupResolvedItemADR {
                
                Button(action: { isPOISheet.toggle() }, label: { Text("Present POI Sheet") })

                Button(action: { isAddressSheet.toggle() }, label: { Text("Present address Sheet") })
                    .padding(.top, 20)

            } else {
                VStack {
                    Text(verbatim: "Loading...")
                    ProgressView()
                }
            }
        }
        .task {
            await load()
        }
        .sheet(isPresented: $isPOISheet, onDismiss: {print("STATUS = \(status)")}) {
            LookupPlaceSheetView(lookupResolvedItem: lookupResolvedItemPOI!,
                                 place: $place,
                                 status: $status)
            .presentationBackground(.surface1)
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $isAddressSheet, onDismiss: {print("STATUS = \(status)")}) {
            LookupPlaceSheetView(lookupResolvedItem: lookupResolvedItemADR!,
                                 place: $place,
                                 status: $status)
            .presentationBackground(.surface1)
            .presentationDetents([.medium])
        }
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
    
    private func load() async {
        do {
            self.results = try await mock.addressLookupService.search(query: "la chitarra")
            if let first = results.first {
                let request = MKLocalSearch.Request(completion: first.localSearchCompletion)
                let search = MKLocalSearch(request: request)
                do {
                    let response = try await search.start()
                    guard let item = response.mapItems.first else {
                        let error = URLError(.fileDoesNotExist)
                        throw error
                    }
                    // Return resolved item
                    lookupResolvedItemPOI = LookupResolvedItem(mapItem: item,
                                                            isPOI: true,
                                                            address: item.resolvedAddress() ?? "N/A",
                                                            coordinates: item.resolvedCoordinates(),
                                                            distance: "N/A")
                                        
                } catch {
                    lookupError = error
                }
                
                let other = try await mock.addressLookupService.search(query: "rue du")
                let first2 = other.first(where: { $0.isPOI == false })!
                let request2 = MKLocalSearch.Request(completion: first2.localSearchCompletion)
                let search2 = MKLocalSearch(request: request2)
                let response = try await search2.start()
                guard let item = response.mapItems.first else {
                    let error = URLError(.fileDoesNotExist)
                    throw error
                }
                // Return resolved item
                lookupResolvedItemADR = LookupResolvedItem(mapItem: item,
                                                        isPOI: false,
                                                        address: item.resolvedAddress() ?? "N/A",
                                                        coordinates: item.resolvedCoordinates(),
                                                        distance: "N/A")

                
            } else {
                lookupError = URLError(.badURL)
            }
        } catch {
            self.lookupError = error
        }
    }
}

#Preview {
    NavigationStack {
        VStack {
            MockLookupPlaceSheetView()
                .ignoresSafeArea()
        }
    }
}

#endif
