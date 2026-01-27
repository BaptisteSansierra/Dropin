//
//  CreatePlaceQuickViewFull.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/1/26.
//

import SwiftUI
import CoreLocation

struct CreatePlaceFullView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: CreatePlaceFullViewModel
    @State private var place: PlaceUI
    @FocusState private var isNameFocused

    private var tagIds: [String]?
    private var groupId: String?

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init
    init(viewModel: CreatePlaceFullViewModel,
         coordinates: CLLocationCoordinate2D,
         address: String,
         name: String,
         marker: String?,
         tags: [String],
         group: String?) {
        self._viewModel = State(initialValue: viewModel)
        place = PlaceUI(coordinates: coordinates)
        place.address = address
        place.name = name
        if let marker = marker {
            place.icon = Icon(rawValue: marker)
        }
        self.tagIds = tags
        self.groupId = group
    }

    // MARK: - Body
    var body: some View {
        VStack {
            ScrollView {
                CreatePlaceBasicsView(place: $place,
                                      showingMarkerList: $viewModel.showingMarkerList,
                                      showingTagsSelector: $viewModel.showingTagsSelector,
                                      showingGroupSelector: $viewModel.showingGroupSelector,
                                      isNameFocused: $isNameFocused)
                
                // TODO
                
            }
            Spacer()
            MainButton(text: "create_place.save") {
                createPlace()
            }
        }
        .task {
            if let tagIds = tagIds {
                place.tags = await viewModel.retrieveTags(tagIds: tagIds)
            }
            if let groupId = groupId {
                place.group = await viewModel.retrieveGroup(groupId: groupId)
            }
            
            //await fetchAddress()
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
//    private func fetchAddress() async {
//        print("Fetch address from coords : \(place.coordinates)")
//        // Fetch address from coords
//        place.address = String(localized: "create_place.fetching")
//        do {
//            self.place.address = try await viewModel.fetchAddress(coords: place.coordinates)
//        } catch is CancellationError {
//        } catch {
//            self.place.address = String(localized: "common.na")
//        }
//    }
    
    private func createPlace() {
        Task {
            do {
                try await viewModel.save(place: place)
                viewModel.popToRoot()
            } catch DomainError.Place.missingName {
                viewModel.missingName = true
            } catch {
                // TODO: handle failure
                fatalError("couldn't save place in DB: \(error)")
            }
        }
    }
}


#if DEBUG
struct MockCreatePlaceFullView: View {
    var mock: MockContainer
    @State var tag1: TagUI
    @State var tag2: TagUI
    @State var tag3: TagUI
    @State var group: GroupUI

    var body: some View {
        mock.appContainer.createCreatePlaceFullView(coordinates: DropinApp.locations.paris,
                                                    address: "3 rue de la place",
                                                    name: "nowhere",
                                                    marker: "sf:fork.knife.circle",
                                                    tags: [tag1.id, tag2.id, tag3.id],
                                                    group: group.id)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.tag1 = mock.getTagUI(0)
        self.tag2 = mock.getTagUI(1)
        self.tag3 = mock.getTagUI(2)
        self.group = mock.getGroupUI(0)
    }
}

#Preview {
    MockCreatePlaceFullView()
}

#endif
