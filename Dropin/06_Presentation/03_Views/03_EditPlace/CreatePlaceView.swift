//
//  CreatePlaceView.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/25.
//

import SwiftUI
import CoreLocation
import SwiftData

/*
struct CreatePlaceView: View {
    // MARK: - Properties
    //private var viewModel: CreatePlaceViewModel
    private var placeController: PlaceController
    
    // MARK: - State & Bindings
    //@State private var place: PlaceEntity
    @State private var num: Int = 0

    // MARK: - Init
    init(viewModel: CreatePlaceViewModel, place: PlaceEntity) {
        //self.viewModel = viewModel
        //self._place = State(initialValue: PlaceEntity(coordinates: place.coordinates))
        self.placeController = PlaceController(place: place)
    }

    // MARK: - Body
    var body: some View {
        VStack {
            HStack {
                Text("Name")
                Spacer()
                Text(placeController.place.name)
            }
            .padding()
            HStack {
                Text("Num")
                Spacer()
                Text("\(num)")
            }
            .padding()
            Button("Randomize name") {
                let rando = String(UUID().uuidString.split(separator: "-").first!)
                print("RANDO: \(rando)")
                placeController.place.name = rando
                num += 1
                print("PLACE name : \(placeController.place.name)")
            }
            .padding()
            Button("Make it pipo") {
                //place = PlaceEntity(id: "123", name: "pipo", coordinates: place.coordinates, address: "", systemImage: "tag", tags: [], creationDate: Date.now)
                placeController.place.name = "pipo"
                num += 1
                print("PLACE name : \(placeController.place.name)")
            }
            .padding()
        }
    }
}
*/

struct CreatePlaceView: View {
    
    // MARK: - Properties
    private var viewModel: CreatePlaceViewModel

    // MARK: - State & Bindings
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
    // DB
    //@Query var groups: [SDGroup]
    //@Query var tags: [SDTag]

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    //@Environment(PlaceFactory.self) private var placeFactory

    // MARK: - Init
    init(viewModel: CreatePlaceViewModel, place: PlaceUI) {
        self.viewModel = viewModel
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
                        do {
                            try await viewModel.save(place: place)
                            dismiss()
                        } catch {
                            fatalError("couldn't save place in DB")
                        }
                    } catch {
                        // TODO: handle failure
                        fatalError("Could not save place")
                    }
                }
            }
            .padding()
        }
        .task {
            fetchAddress()
            
            //let pipo = $placeController
            //print("PIPO type : \(type(of: pipo))")
        }
        
        //// TODOOOO
        
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
            MarkerListView(selected: $place.systemImage)
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
/*
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
*/
#endif
