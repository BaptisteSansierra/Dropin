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

    // MARK: - init
    init(viewModel: LookupPlacesViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body
    var body: some View {
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
                            Color.gray
                                .opacity(0.25)
                                .ignoresSafeArea()
                            ProgressView()
                        }
                    }
                }
            } else {
                noConnectionView
            }
            Spacer()
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
        .sheet(item: $viewModel.resolvedPlace,
               content: { item in
            viewModel.createLookupPlaceView(item)
                .presentationBackground(.ultraThinMaterial)
        })
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
            Label("Error while fetching", systemImage: "exclamationmark.triangle")
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
                if viewModel.results.count > 0 {
                    Color.gray
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .opacity(0.25)
                }
                VStack {
                    ProgressView()
                        .frame(height: 100)
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        if viewModel.query.count > 2 {
            ContentUnavailableView {
                Label("No result matching", systemImage: "chart.xyaxis.line")
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
