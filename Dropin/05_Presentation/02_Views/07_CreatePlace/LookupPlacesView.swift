//
//  LookupPlacesView.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/12/25.
//

import SwiftUI
import MapKit

struct LookupPlacesView: View {
    
    // MARK: - States & Bindings
    @State private var viewModel: LookupPlacesViewModel
    // editedPlace is provided when (and only when) the user is editing address from an existing place
    @Binding private var editedPlace: PlaceUIModel?
    // draftPlace is provided when credating a place from scratch
    // it arrives nil and a place is effectively created if validated by user
    @Binding private var draftPlace: PlaceUIModel?

    private var initialAddress = ""

    // MARK: - init
    init(viewModel: LookupPlacesViewModel, draftPlace: Binding<PlaceUIModel?>) {
        viewModel.resultOffset = UIScreen.main.bounds.height
        self.viewModel = viewModel
        self._editedPlace = .constant(nil)
        self._draftPlace = draftPlace
        #if DEBUG
        initialAddress = "la grange"
        #endif
    }

    init(viewModel: LookupPlacesViewModel, place: Binding<PlaceUIModel>) {
        viewModel.resultOffset = UIScreen.main.bounds.height
        self.viewModel = viewModel
        self._editedPlace = Binding<PlaceUIModel?>(get: {
            place.wrappedValue
        }, set: { value in
            guard value != nil else { return }
            place.wrappedValue = value!
        })
        self._draftPlace = .constant(nil)
        Log.debug("LOOKUP FROM PLACE => Set address to '\(place.wrappedValue.address ?? "")'")
        self.initialAddress = place.wrappedValue.address ?? ""
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                SearchTextFieldView(text: $viewModel.query,
                                    placeholder: "Search a name or an address")
                .padding(.horizontal)
                .padding(.bottom, 20)
                Divider()
                if viewModel.reachabilityService.isConnected {
                    if let _ = viewModel.lookupError {
                        errorView
                    } else {
                        ZStack {
                            if viewModel.results.count > 0 || viewModel.searching {
                                resultsView
                            } else {
                                placeholderView
                            }
                            if viewModel.resolving {
                                loadingView
                            }
                        }
                    }
                } else {
                    noConnectionView
                }
                Spacer()
            }
            if let resolvedPlace = $viewModel.resolvedPlace.wrappedValue {
                
//                Rectangle()
//                    .fill(.regularMaterial)
//                    .opacity(viewModel.resultBgOpacity)
//                    .ignoresSafeArea()

                Color.overlayAlphaLayer
                    .opacity(viewModel.resultBgOpacity)
                    .ignoresSafeArea()
                
                viewModel.createLookupPlaceView(resolvedPlace,
                                                place: $editedPlace,
                                                status: $viewModel.resultStatus)
                    .offset(x: 0, y: viewModel.resultOffset)
            }
        }
        .navigationTitle(viewModel.isEditMode() ? "common.edit_address" : "common.save_new_place")
        .navigationBarTitleDisplayMode(.inline)
// Use Apple default ?
//        .searchable(text: $searchText,
//                    placement: .navigationBarDrawer,
//                    prompt: "Do your math")
        .task {
            viewModel.query = initialAddress
        }
        .onChange(of: viewModel.resultStatus) { _, newValue in
            completeLookup(newValue)
        }
        .onChange(of: viewModel.resolvedPlaceComputed) { oldValue, newValue in
            guard !oldValue && newValue else { return }
            viewModel.resultStatus = .pending
            withAnimation {
                viewModel.resultOffset = 0
                viewModel.resultBgOpacity = 1
            }
        }
        .onChange(of: viewModel.reachabilityService.isConnected) { oldValue, newValue in
            if newValue {
                viewModel.updateQuery()
            } else {
                viewModel.resetResults()
            }
        }
    }
    
    // MARK: - Subviews
    private var errorView: some View {
        ContentUnavailableView {
            Label("error.fetching", systemImage: "exclamationmark.triangle")
        } description: {
            if let error = viewModel.lookupError {
                Text(error.localizedDescription)
                    .textStyle(.body)
            }
        }
    }
    
    private var noConnectionView: some View {
        ContentUnavailableView {
            Label("error.no_connection", systemImage: "antenna.radiowaves.left.and.right.slash")
        }
    }

    private var resultsView: some View {
        ZStack {
            HStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.results, id: \.id) { item in
                            Button {
                                presentDetails(item)
                            } label: {
                                itemCell(item)
                            }
                            Divider()
                        }
                    }
                }

            }
            if viewModel.searching {
                loadingView
            }
        }
    }
    
    private var loadingView: some View {
        DropinLoader(caption: "lookup.searching")
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        if viewModel.query.count > 2 {
            ContentUnavailableView {
                Label("error.no_matching_results", systemImage: "chart.xyaxis.line")
            }
        } else {
            EmptyView()
        }
    }
    
    private func itemCell(_ item: LookupResult) -> some View {
        VStack(spacing: 0) {
            Text(item.localSearchCompletion.title)
                .textStyle(.cellTitle)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 15)
            Text(item.localSearchCompletion.subtitle)
                .textStyle(.cellSubtitle)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
                .padding(.bottom, 15)
        }
        .padding(.horizontal)
    }
    
    // MARK: - private methods
    private func presentDetails(_ lookupResult: LookupResult) {
        UIApplication.dismissKeyboard()
        Task {
            await viewModel.resolvePlace(lookupResult)
        }
    }
    
    private func completeLookup(_ status: LookupPlaceView.PresentationStatus) {
        switch status {
            case .cancelled:
                hideDetailView()
            case .validated(let item):
                hideDetailView()
                if viewModel.isEditMode() {
                    // Apply change on the existing place and pop
                    guard let editedPlace = editedPlace else { return }
                    editedPlace.address = item.address
                    editedPlace.coordinates = item.coordinates
                    Task {
                        do {
                            try await viewModel.updatePlace(editedPlace)
                        } catch {
                            assertionFailure("Couldn't update place \(editedPlace.name)")
                        }
                    }
                    viewModel.popToRoot()
                } else {
                    // Create a draftPlace and push CreatePlaceFullView
                    draftPlace = PlaceUIModel(name: item.name,
                                              coordinates: item.coordinates,
                                              address: item.address)
                    viewModel.pushCreatePlaceFullView(lookupResolvedItem: item)
                }
            case .pending:
                () // pending means pending...
        }
    }
    
    private func hideDetailView() {
        withAnimation {
            viewModel.resultOffset = UIScreen.main.bounds.height
            viewModel.resultBgOpacity = 0
        } completion: {
            viewModel.resolvedPlaceComputed = false
            viewModel.resolvedPlace = nil
            viewModel.resultStatus = .pending
        }
    }

}

#if DEBUG

struct MockLookupPlacesView: View {
    var mock: MockContainer
    @State var draftPlace: PlaceUIModel?

    var body: some View {
        mock.appContainer.createLookupPlacesView(draftPlace: $draftPlace)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
    }
}

#Preview {
    NavigationStack {
        MockLookupPlacesView()
    }
}

#endif
