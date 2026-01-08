//
//  LookupPlacesView.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/12/25.
//

import SwiftUI
import MapKit


struct CustomOverlay<Item: NSObject, OverlayContent: View>: ViewModifier {
    
    var item: Item?
    @ViewBuilder let overlayContent: () -> OverlayContent
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let _ = item {
            content.overlay {
                overlayContent()
                
//                Color.red
//                    .opacity(0.3)
//                    .ignoresSafeArea()
            }
        } else {
            content
        }
    }
}


struct LookupPlacesView: View {
    
    // MARK: - States & Bindings
    @State private var viewModel: LookupPlacesViewModel
    @State private var selected: LookupResult? {
        didSet {
//            if selected == nil {
//                print("DIDSet selected NIIIL")
//            } else {
//                print("DIDSet selected = \(selected!.item.title)")
//            }
        }
    }
    @State private var showDetails: Bool = false

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
            if let _ = viewModel.lookupError {
                errorView
            } else {
                if viewModel.results.count > 0 {
                    resultsView
                } else {
                    placeholderView
                }
            }
            Spacer()
        }
        .navigationTitle("common.save_new_place")
        .navigationBarTitleDisplayMode(.inline)
//        .searchable(text: $searchText,
//                    placement: .navigationBarDrawer,
//                    prompt: "Do your math")
        .task {
            #if DEBUG
            viewModel.query = "ddd"
            #endif
        }
        .fullScreenCover(isPresented: $showDetails,
                         onDismiss: {
                             selected = nil
                         },
                         content: {
            if let selected = selected {
                viewModel.createLookupPlaceView(selected)
            } else {
                //_ = assertionFailure("undefined")
                EmptyView()
                //fatalError("unexpected undefined MKLocalSearchCompletion")
                // print("OUlalalalal")
            }
        })
//        .modifier(CustomOverlay(item: selected, overlayContent: {
//
////            Color.red
////                .opacity(0.3)
////                .ignoresSafeArea()
//            if let selected = selected {
//                viewModel.createLookupPlaceView(selected)
//            } else {
//                EmptyView()
//            }
//
//        }))
    }
        
    // MARK: - Subviews
    private var errorView: some View {
        ContentUnavailableView {
            Label("Error while fetching", systemImage: "exclamationmark.triangle")
        } description: {
            if let error = viewModel.lookupError {
                Text(error.localizedDescription)
            }
        }
    }
    
    private var resultsView: some View {
        List {
            ForEach(viewModel.results, id: \.id) { item in
                
                Button {
                    presentDetails(item)
                } label: {
                    itemCell(item)
                }

                
//                NavigationLink {
//                    viewModel.createLookupPlaceView(item)
//                } label: {
//                    itemCell(item)
//                }
            }
        }
        .listStyle(.inset)
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
                .cellTitleFormater()
            Text(item.localSearchCompletion.subtitle)
                .cellSubtitleFormater()
        }
    }
    
    // MARK: - private methods
    private func presentDetails(_ lookupResult: LookupResult) {
        selected = lookupResult
        showDetails = true
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
