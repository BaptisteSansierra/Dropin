//
//  CreatePlaceView.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/25.
//

import SwiftUI
import CoreLocation
import SwiftData

struct CreatePlaceView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: CreatePlaceViewModel
    @State private var place: PlaceUI
    @State private var showingMarkerList = false
    @State private var showingTagsSelector = false
    @State private var showingGroupSelector = false
    @State private var selectedGroup: SDGroup?
    @State private var showPhoneField = false
    @State private var showUrlField = false
    @State private var showNotesField = false
    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var editEnabled = true
    private var phone: Binding<String> {
        Binding<String>(
            get: {
                return place.phone ?? ""
            }, set: { value in
                place.phone = value
            })
    }
    private var url: Binding<String> {
        Binding<String>(
            get: {
                return place.url ?? ""
            }, set: { value in
                place.url = value
            })
    }
    private var notes: Binding<String> {
        Binding<String>(
            get: {
                return place.notes ?? ""
            }, set: { value in
                place.notes = value
            })
    }

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init
    init(viewModel: CreatePlaceViewModel, place: PlaceUI) {
        self._viewModel = State(initialValue: viewModel)
        self._place = State(initialValue: place)
    }

    // MARK: - Body
    var body: some View {
        // Content
        VStack {
            //NewPlaceFixedMap(place: wipPlace)
            ScrollView {
                PlaceHeaderView(place: $place,
                                showingMarkerList: $showingMarkerList,
                                showPhoneField: $showPhoneField,
                                showUrlField: $showUrlField,
                                showNotesField: $showNotesField,
                                editEnabled: editEnabled)
                PlaceStringFieldView(field: phone,
                                     showField: $showPhoneField,
                                     name: "common.phone",
                                     keyboardType: .phonePad,
                                     editEnabled: editEnabled)
                    .tag("phone")
                PlaceStringFieldView(field: url,
                                     showField: $showUrlField,
                                     name: "common.url",
                                     keyboardType: .URL,
                                     editEnabled: editEnabled)
                    .tag("url")
                PlaceTagsView(place: $place,
                              showingTagsSelector: $showingTagsSelector,
                              editEnabled: editEnabled)
                PlaceGroupView(place: $place,
                               showingGroupSelector: $showingGroupSelector,
                               editEnabled: editEnabled)
                PlaceNotesView(notes: notes,
                               showNotesField: $showNotesField,
                               scrollPosition: $scrollPosition,
                               editEnabled: editEnabled)
            }
            .scrollPosition($scrollPosition)
            Spacer()
            Divider()
            Button("create_place.save") {
                Task {
                    do {
                        try await viewModel.save(place: place)
                        dismiss()
                    } catch {
                        // TODO: handle failure
                        fatalError("couldn't save place in DB")
                    }
                }
            }
            .padding()
        }
        .task {
            fetchAddress()
        }
        .sheet(isPresented: $showingTagsSelector) {
            viewModel.createTagSelectorViewModel(place: $place)
                .padding(.top, 20)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingGroupSelector) {
            viewModel.createGroupSelectorViewModel(place: $place)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showingMarkerList) {
            MarkerListView(selected: $place.sfSymbol)
        }
    }
        
    // MARK: - Actions
    private func fetchAddress() {
        // TODO: convert to async by using continuation (withCheckedContinuation)

        print("Fetch address from coords : \(place.coordinates)")
        
        // Fetch address from coords
        place.address = String(localized: "create_place.fetching")
        LocationManager.lookUpAddress(coords: place.coordinates) { address in
            guard let address = address else {
                self.place.address = String(localized: "common.na")
                return
            }
            self.place.address = address
            print("Address fetched : \(address)")

        }
    }
}

#if DEBUG
struct MockCreatePlaceView: View {
    var mock: MockContainer
    @State var place: PlaceUI

    var body: some View {
        mock.appContainer.createCreatePlaceView(place: place)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(0)
    }
}

#Preview {
    MockCreatePlaceView()
        .environment(NavigationContext())
}

#endif
