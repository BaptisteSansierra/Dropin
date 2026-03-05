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
    @State private var resultOffset: CGFloat
    @State private var resultStatus: LookupPlaceView.PresentationStatus = .pending
    @State private var resultBgOpacity: CGFloat = 0

    // MARK: - init
    init(viewModel: LookupPlacesViewModel) {
        self.viewModel = viewModel
        self.resultOffset = UIScreen.main.bounds.height
    }

    // MARK: - Body
    var body: some View {
        ZStack {
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
                Color.overlayAlphaLayer
                    .opacity(resultBgOpacity)
                    .ignoresSafeArea()
                viewModel.createLookupPlaceView(resolvedPlace,
                                                status: $resultStatus)
                    .offset(x: 0, y: resultOffset)
            }
        }
        .navigationTitle("common.save_new_place")
        .navigationBarTitleDisplayMode(.inline)
// Use Apple default ?
//        .searchable(text: $searchText,
//                    placement: .navigationBarDrawer,
//                    prompt: "Do your math")
        .task {
            #if DEBUG
            viewModel.query = "ddd"
            #endif
        }
        .onChange(of: resultStatus) { oldValue, newValue in
            switch newValue {
                case .cancelled:
                    withAnimation {
                        resultOffset = UIScreen.main.bounds.height
                        resultBgOpacity = 0
                    } completion: {
                        viewModel.resolvedPlaceComputed = false
                        viewModel.resolvedPlace = nil
                        resultStatus = .pending
                    }
                case .validated:
                    Task {
                        try await Task.sleep(for: .seconds(0.5))
                        resultOffset = UIScreen.main.bounds.height
                        resultBgOpacity = 0
                        viewModel.resolvedPlaceComputed = false
                        viewModel.resolvedPlace = nil
                        resultStatus = .pending
                    }
                default:
                    ()
            }
        }
        .onChange(of: viewModel.resolvedPlaceComputed) { oldValue, newValue in
            if !oldValue && newValue {
                resultStatus = .pending
                withAnimation {
                    resultOffset = 0
                    resultBgOpacity = 1

                }
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
            List {
                ForEach(viewModel.results, id: \.id) { item in
                    Button {
                        presentDetails(item)
                    } label: {
                        itemCell(item)
                    }
                }
            }
            .listStyle(.inset)
            if viewModel.searching {
                loadingView
            }
        }
    }
    
    private var loadingView: some View {
        ZStack {
            RoundedRectangle(cornerSize: 8)
                .frame(width: 100, height: 100)
                .foregroundStyle(.backgroundPrimary)
                .shadow(radius: 5)
            ProgressView()
        }
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
        VStack(alignment: .leading) {
            Text(item.localSearchCompletion.title)
                .textStyle(.cellTitle)
            Text(item.localSearchCompletion.subtitle)
                .textStyle(.cellSubtitle)
        }
    }
    
    // MARK: - private methods
    private func presentDetails(_ lookupResult: LookupResult) {
        Task {
            
            await viewModel.resolvePlace(lookupResult)
        }
    }
}

#if DEBUG

struct MockLookupPlacesView: View {
    var mock: MockContainer

    var body: some View {
        mock.appContainer.createLookupPlacesView()
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
