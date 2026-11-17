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
    
    // MARK: - Private properties
    // editedPlace is provided when (and only when) the user is editing address from an existing place
    private var editedPlace: PlaceUIModel?
    private let onSelect: (LookupResolvedItem) -> Void
    private var presentingResolveError: Binding<Bool> {
        Binding {
            viewModel.resolveError != nil
        } set: { v in
            if !v { viewModel.resolveError = nil }
        }
    }

    // MARK: - init
    init(viewModel: LookupPlacesViewModel,
         editedPlace: PlaceUIModel?,
         onSelect: @escaping (LookupResolvedItem) -> Void ) {
        viewModel.resultOffset = UIScreen.main.bounds.height
        self.viewModel = viewModel
        self.editedPlace = editedPlace
        self.onSelect = onSelect
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                SearchTextFieldView(text: $viewModel.query,
                                    placeholder: "Search a name or an address")
                .padding(.horizontal)
                .padding(.bottom, 10)
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
        }
        .navigationTitle(editedPlace != nil ? "common.edit_address" : "common.save_new_place")
        .navigationBarTitleDisplayMode(.inline)
        .taskOnce {
            // Get the initial address if a place is provided
            var initialAddress: String = ""
            if let editedPlace = editedPlace {
                initialAddress = editedPlace.address ?? ""
            }
            #if DEBUG
            if initialAddress.isEmpty {
                initialAddress = "la grange"
            }
            #endif
            viewModel.query = initialAddress
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
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(viewModel.results.enumerated()), id: \.element.id) { idx, item in
                        Button {
                            presentDetails(item)
                        } label: {
                            itemCell(item)
                        }
                        if idx != viewModel.results.count - 1 {
                            Rectangle()
                                .fill(.hairline)
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                                //.padding(.leading, 70)
                        }
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.surface1)
                }
            }
            .padding(.horizontal)
            if viewModel.searching {
                loadingView
            }
        }
        .alertError(error: $viewModel.resolveError)
        .sheet(item: $viewModel.resolvedPlace) {
            if viewModel.resultStatus == .pending {
                viewModel.resultStatus = .cancelled
            }
            completeLookup(viewModel.resultStatus)
        } content: { resolvedPlace in
            LookupPlaceSheetView(lookupResolvedItem: resolvedPlace,
                                 status: $viewModel.resultStatus,
                                 place: editedPlace)
            .presentationBackground(.surface1)
            .presentationDetents([.medium])
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
        HStack(spacing: 0) {
            ZStack(alignment: .center) {
                Circle()
                    .fill(item.isPOI ? .dropinPrimary : .backgroundPrimary)
                    .frame(width: 35, height: 35)
                Image(systemName: item.isPOI ? "storefront.fill" : "mappin")
                    .foregroundStyle(item.isPOI ? .surface1 : .textTertiary)
                    .font(.footnote)
            }
            .padding(.trailing)
            VStack(spacing: 0) {
                Text(highlighted(item.localSearchCompletion.title,
                                 ranges: item.localSearchCompletion.titleHighlightRanges,
                                 font: TextStyle.cellTitle.font,
                                 color: .textPrimary))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 15)
                Text(highlighted(item.localSearchCompletion.subtitle,
                                 ranges: item.localSearchCompletion.subtitleHighlightRanges,
                                 font: TextStyle.cellSubtitle.font,
                                 color: .textSecondary))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
                .padding(.bottom, 15)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - private methods
    func highlighted(_ text: String,
                     ranges: [NSValue],
                     font: Font,
                     color: Color) -> AttributedString {
        var attr = AttributedString(text)
        attr.font = font.weight(.regular)
        attr.foregroundColor = color
        for value in ranges {
            guard let r = Range(value.rangeValue, in: text),
                  let ar = Range(r, in: attr) else {
                continue
            }
            attr[ar].font = font.weight(.semibold)
            attr[ar].foregroundColor = color
        }
        return attr
    }
    
    private func presentDetails(_ lookupResult: LookupResult) {
        UIApplication.dismissKeyboard()
        Task {
            await viewModel.resolvePlace(lookupResult)
        }
    }
    
    private func completeLookup(_ status: LookupPlaceSheetView.PresentationStatus) {
        switch status {
            case .cancelled:
                hideDetailView()
            case .validated(let item):
                hideDetailView()
                onSelect(item)
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
    @State var draftPlacePOI: MKPointOfInterestCategory?
    @State var draftPlaceColor: Color?

    var body: some View {
        mock.appContainer.createLookupPlacesView { item in
            print("Address: \(item.address)")
            if let poiCategory = item.mapItem.pointOfInterestCategory {
                print("POI: \(poiCategory)")
            } else {
                print("POI: N/A")
            }
        }
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
