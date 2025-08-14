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
                return placeFactory.place.phone ?? ""
            }, set: { value in
                placeFactory.place.phone = value
            })
    }
    private var url: Binding<String> {
        Binding<String>(
            get: {
                return placeFactory.place.url ?? ""
            }, set: { value in
                placeFactory.place.url = value
            })
    }
    private var notes: Binding<String> {
        Binding<String>(
            get: {
                return placeFactory.place.notes ?? ""
            }, set: { value in
                placeFactory.place.notes = value
            })
    }
    // DB
    //@Query var groups: [SDGroup]
    //@Query var tags: [SDTag]

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PlaceFactory.self) private var placeFactory

    // MARK: - Body
    var body: some View {
        // Bindable
        @Bindable var placeFactory = placeFactory
        @Bindable var wipPlace = placeFactory.place

        // Content
        VStack {
            //NewPlaceFixedMap(place: wipPlace)
            ScrollView {
                PlaceHeaderView(place: $placeFactory.place,
                                showingMarkerList: $showingMarkerList,
                                showPhoneField: $showPhoneField,
                                showUrlField: $showUrlField,
                                showNotesField: $showNotesField,
                                editEnabled: editEnabled)
                PlaceStringFieldView(field: phone,
                                     showField: $showPhoneField,
                                     name: "Phone",
                                     keyboardType: .phonePad,
                                     editEnabled: editEnabled)
                    .tag("phone")
                PlaceStringFieldView(field: url,
                                     showField: $showUrlField,
                                     name: "URL",
                                     keyboardType: .URL,
                                     editEnabled: editEnabled)
                    .tag("url")
                PlaceTagsView(place: $placeFactory.place,
                              showingTagsSelector: $showingTagsSelector,
                              editEnabled: editEnabled)
                PlaceGroupView(place: $placeFactory.place,
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
            Button("Save this place") {
                placeFactory.save(modelContext: modelContext)
                dismiss()
            }
            .padding()
        }
        .onFirstAppear {
            onFirstAppear(place: wipPlace)
        }
        .sheet(isPresented: $showingTagsSelector) {
            TagSelectorView()
                .environment(placeFactory.place)
                .padding(.top, 20)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingGroupSelector) {
            GroupSelectorView()
                .environment(placeFactory.place)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showingMarkerList) {
            MarkerListView(selected: $wipPlace.systemImage)
        }
    }
        
    // MARK: - Actions
    private func onFirstAppear(place: Place) {
        // Fetch address from coords
        place.address = "Fetching address..."
        LocationManager.lookUpAddress(coords: place.coordinates) { address in
            guard let address = address else {
                place.address = "N/A"
                return
            }
            place.address = address
        }
    }
}

#if DEBUG

private struct CLVPreview: View {

    let container: ModelContainer
    @State private var placeFactory = PlaceFactory.preview
    
    init() {
        print("CREATE TSVPreview")
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: SDPlace.self, configurations: config)
        } catch {
            fatalError("couldn't create model container")
        }
        for item in SDTag.all {
            container.mainContext.insert(item)
        }
        for item in SDGroup.all {
            container.mainContext.insert(item)
        }
        for item in SDPlace.all {
            container.mainContext.insert(item)
        }
        placeFactory.place.name = "My lovely place"
        placeFactory.place.tags = [SDTag.t4, SDTag.t8, SDTag.t11]
        placeFactory.place.group = SDGroup.g2

        do {
            try container.mainContext.save()
        } catch {
            print("COULDN t save DB")
        }
        print(container)
    }
    
    var body: some View {
        CreatePlaceView()
            .modelContainer(container)
            .environment(placeFactory)
    }
}

#Preview {
    CLVPreview()
}

#endif
