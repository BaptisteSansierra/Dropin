//
//  CreatePlaceQuickView.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI

struct CreatePlaceQuickView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: CreatePlaceQuickViewModel
    @State private var place: PlaceUI
    @FocusState private var isNameFocused

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init
    init(viewModel: CreatePlaceQuickViewModel, place: PlaceUI) {
        self._viewModel = State(initialValue: viewModel)
        self._place = State(initialValue: place)
    }

    // MARK: - Body
    var body: some View {
        // Content
        VStack {
            CreatePlaceBasicsView(place: $place,
                                  showingMarkerList: $viewModel.showingMarkerList,
                                  showingTagsSelector: $viewModel.showingTagsSelector,
                                  showingGroupSelector: $viewModel.showingGroupSelector,
                                  isNameFocused: $isNameFocused)
            Spacer()
            SecondaryButton(text: "create_place.moreOptions", action: moreOptions)
                .padding(.bottom, 15)
            MainButton(text: "create_place.save", action: createPlace)
        }
        .task {
            await fetchAddress()
        }
        .sheet(isPresented: $viewModel.showingTagsSelector) {
            viewModel.createTagSelectorView(place: $place)
                .padding(.top, 20)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingGroupSelector) {
            viewModel.createGroupSelectorView(place: $place)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $viewModel.showingMarkerList) {
            MarkerListView(selected: $place.icon)
        }
        .alert("alert.missing_name.title", isPresented: $viewModel.missingName) {
            Button("common.ok") {
                isNameFocused = true
            }
        } message: {
            Text("alert.missing_name.body")
        }
    }

    // MARK: - Actions
    private func fetchAddress() async {
        print("Fetch address from coords : \(place.coordinates)")
        // Fetch address from coords
        place.address = String(localized: "create_place.fetching")
        do {
            self.place.address = try await viewModel.fetchAddress(coords: place.coordinates)
        } catch is CancellationError {
        } catch {
            self.place.address = String(localized: "common.na")
        }
    }
    
    private func createPlace() {
        Task {
            do {
                try await viewModel.save(place: place)
                dismiss()
            } catch DomainError.Place.missingName {
                viewModel.missingName = true
            } catch {
                // TODO: handle failure
                fatalError("couldn't save place in DB: \(error)")
            }
        }
    }
    
    private func moreOptions() {
        dismiss()
        viewModel.pushCreatePlaceFullView(place: place)
    }
}


#if DEBUG
struct MockCreatePlaceQuickView: View {
    var mock: MockContainer
    @State var place: PlaceUI

    var body: some View {
        mock.appContainer.createCreatePlaceQuickView(place: place)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(0)
    }
}

#Preview {
    MockCreatePlaceQuickView()
}

#endif
