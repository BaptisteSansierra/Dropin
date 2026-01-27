//
//  LookupPlaceView.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/12/25.
//

import SwiftUI
import Contacts

struct LookupPlaceView: View {
    
    enum PresentationStatus {
        case cancelled
        case validated
        case pending
    }
    
    // MARK: - States & Bindings
    @State private var viewModel: LookupPlaceViewModel
    @Binding private var status: PresentationStatus

    // MARK: - init
    init(viewModel: LookupPlaceViewModel, status: Binding<LookupPlaceView.PresentationStatus>) {
        self.viewModel = viewModel
        self._status = status
    }
    
    // MARK: - body
    var body: some View {
        VStack {
            Spacer()
            contentView(viewModel.lookupResolvedItem)
            Spacer()
            HStack {
                Spacer()
                cancelButton
                Spacer()
                confirmButton
                Spacer()
            }
            Spacer()
        }
    }
    
    private var cancelButton: some View {
        Button {
            cancel()
        } label: {
            ZStack {
                Circle()
                    .fill(.backgroundPrimary)
                    .stroke(.destructive, style: StrokeStyle(lineWidth: 2))
                    .frame(width: 60, height: 60)
                Image(systemName: "multiply")
                    .font(.system(size: 30))
                    .foregroundStyle(.destructive)
                    .opacity(0.5)
            }
            .padding(.trailing, 20)
        }
    }
    
    private var confirmButton: some View {
        Button {
            confirm()
        } label: {
            ZStack {
                Circle()
                    .fill(.backgroundPrimary)
                    .stroke(.dropinPrimary, style: StrokeStyle(lineWidth: 2))
                    .frame(width: 60, height: 60)
                Image(systemName: "plus")
                    .font(.system(size: 30))
                    .foregroundStyle(.dropinPrimary)
                    .opacity(0.5)
            }
            .padding(.leading, 20)
        }
    }

    
    // MARK: - subviews
    private var loadingView: some View {
        VStack {
            Text("common.loading.susp")
                .textStyle(.body)
            ProgressView()
        }
    }

    private func contentView(_ item: LookupResolvedItem) -> some View {
        VStack {
            Map(position: $viewModel.camera,
                interactionModes: []) {
                markerResolvingName(for: item)
                UserAnnotation()
            }
            .overlay {
                HStack {
                    Spacer()
                    VStack(spacing: 0){
                        Spacer()
                        MapIcoButton(systemImage: "plus",
                                     imageFrame: CGSize(width: 15, height: 15),
                                     color: viewModel.cameraDistance < 125 ? .disabled : .dropinPrimary,
                                     action: { viewModel.zoomIn() })
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 15, trailing: 10))
                        MapIcoButton(systemImage: "minus",
                                     imageFrame: CGSize(width: 15, height: 15),
                                     color: viewModel.cameraDistance >= 32_768_000 ? .disabled : .dropinPrimary,
                                     action: { viewModel.zoomOut() })
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 15, trailing: 10))
                    }
                }
            }
            .onAppear {
                viewModel.updateCamera(coordinates: item.coordinates)
            }
            .frame(height: 350)
            .padding(.bottom, 10)
            HStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(.dropinPrimary)
                        .frame(width: 30, height: 30)
                    if let icon = item.icon {
                        IconView(icon: icon)
                            .sizeCaption2()
                            .foregroundStyle(.backgroundPrimary)
                            .padding(.horizontal, 0)
                    } else {
                        Image(systemName: "signpost.right.and.left")
                            .font(.caption2)
                            .foregroundStyle(.backgroundPrimary)
                            .padding(.horizontal, 0)
                    }
                }
                .padding(.leading)
                VStack(alignment: .leading, spacing: 0) {
                    textResolvingName(for: item)
                        .textStyle(.cellTitle)
                        .padding(.vertical, 5)
                    Text(item.address)
                        .textStyle(.cellSubtitle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                if let distance = item.distance {
                    Text(distance)
                        .textStyle(.cellDetail)
                        .padding(.trailing)
                }
            }
            .padding(.bottom)

        }
        .cornerRadius(25)
        .background(.clear)
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(.backgroundPrimary)
                .shadow(color: .textPrimary.opacity(0.4), radius: 6, x: 2, y: -3)
        }
        .padding()
    }
    
    // MARK: - private methods
    private func textResolvingName(for item: LookupResolvedItem) -> Text {
        switch item.type {
            case .address:
                return Text("common.new_place")
            case .poi:
                if let name = item.name {
                    return Text(verbatim: name)
                } else {
                    assertionFailure("undefined name for POI")
                    return Text("common.new_place")
                }
        }
    }
    
    private func markerResolvingName(for item: LookupResolvedItem) -> some MapContent {
        switch item.type {
            case .address:
                return Marker("common.new_place",
                              systemImage: item.mapItem.icon().name,
                              coordinate: item.coordinates)
            case .poi:
                if let name = item.name {
                    return Marker(name,
                                  systemImage: item.mapItem.icon().name,
                                  coordinate: item.coordinates)
                } else {
                    assertionFailure("undefined name for POI")
                    return Marker("common.new_place",
                                  systemImage: item.mapItem.icon().name,
                                  coordinate: item.coordinates)
                }
        }
    }
    
    private func confirm() {
        status = .validated
        viewModel.pushCreatePlaceFullView()
    }
    
    private func cancel() {
        status = .cancelled
    }
}



#if DEBUG

import MapKit

struct MockLookupPlaceView: View {
    var mock: MockContainer
    @State private var results: [LookupResult] = []
    @State private var lookupResolvedItem: LookupResolvedItem?
    @State private var lookupError: Error?
    @State private var status: LookupPlaceView.PresentationStatus = .pending

    var body: some View {
        VStack {
            if let error = lookupError {
                VStack {
                    Text(verbatim: "Error")
                    Text(error.localizedDescription)
                }
            } else if let lookupResolvedItem = lookupResolvedItem {
                mock.appContainer.createLookupPlaceView(lookupResolvedItem: lookupResolvedItem,
                                                        status: $status)
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
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
    
    private func load() async {
        do {
            //self.results = try await mock.addressLookupService.search(query: "la chitarra")
            self.results = try await mock.addressLookupService.search(query: "5 rue chevalet")
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
                    if let poi = item.pointOfInterestCategory {
                        lookupResolvedItem = LookupResolvedItem(mapItem: item,
                                                                address: item.resolvedAddress() ?? "N/A",
                                                                coordinates: item.resolvedCoordinates(),
                                                                distance: "N/A",
                                                                name: item.name,
                                                                pointOfInterestCategory: poi,
                                                                icon: item.icon())
                    } else {
                        lookupResolvedItem = LookupResolvedItem(mapItem: item,
                                                                address: item.resolvedAddress() ?? "N/A",
                                                                coordinates: item.resolvedCoordinates(),
                                                                distance: "N/A")
                    }
                } catch {
                    lookupError = error
                }
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
            MockLookupPlaceView()
                .ignoresSafeArea()
        }
    }
}

#endif
