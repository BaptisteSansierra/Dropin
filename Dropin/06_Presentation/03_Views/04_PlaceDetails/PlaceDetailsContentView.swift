//
//  PlaceDetailsContentView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI

enum PlaceEditMode {
    case none
    case edit
    case cancel
    case apply
}

struct PlaceDetailsContentView: View {

    // MARK: - Properties
    let viewModel: PlaceDetailsContentViewModel

    // MARK: - State & Bindings
    @Binding private var place: PlaceUI
    @Binding private var editMode: PlaceEditMode
    @State private var showingMarkerList = false
    @State private var showingTagsSelector = false
    @State private var showingGroupSelector = false
    @State private var showPhoneField: Bool
    @State private var showUrlField: Bool
    @State private var showNotesField: Bool
    @State private var scrollPosition = ScrollPosition(edge: .top)
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

    var body: some View {
        VStack {
            ScrollView {
                PlaceHeaderView(place: $place,
                                showingMarkerList: $showingMarkerList,
                                showPhoneField: $showPhoneField,
                                showUrlField: $showUrlField,
                                showNotesField: $showNotesField,
                                editEnabled: editMode == .edit)
                PlaceStringFieldView(field: phone,
                                     showField: $showPhoneField,
                                     name: "common.phone",
                                     keyboardType: .phonePad,
                                     editEnabled: editMode == .edit)
                    .tag("phone")
                PlaceStringFieldView(field: url,
                                     showField: $showUrlField,
                                     name: "common.url",
                                     keyboardType: .URL,
                                     editEnabled: editMode == .edit)
                    .tag("url")
                PlaceTagsView(place: $place,
                              showingTagsSelector: $showingTagsSelector,
                              editEnabled: editMode == .edit)
                PlaceGroupView(place: $place,
                               showingGroupSelector: $showingGroupSelector,
                               editEnabled: editMode == .edit)
                PlaceNotesView(notes: notes,
                               showNotesField: $showNotesField,
                               scrollPosition: $scrollPosition,
                               editEnabled: editMode == .edit)
            }
            .scrollPosition($scrollPosition)
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
            MarkerListView(selected: $place.systemImage)
        }
        .onChange(of: editMode) { oldValue, newValue in
            if oldValue == .edit && newValue == .cancel {
                showPhoneField = place.phone != nil
                showUrlField = place.url != nil
                showNotesField = place.notes != nil
            }
        }
    }
    
    // MARK: - init
    init(viewModel: PlaceDetailsContentViewModel, place: Binding<PlaceUI>, editMode: Binding<PlaceEditMode>) {
        print("CREATE PlaceDetailsContentViewModel")
        self.viewModel = viewModel
        self._place = place
        self._editMode = editMode
        self._showPhoneField = State(initialValue: place.wrappedValue.phone != nil)
        self._showUrlField = State(initialValue: place.wrappedValue.url != nil)
        self._showNotesField = State(initialValue: place.wrappedValue.notes != nil)
    }
}

/*
#if DEBUG
#Preview {
    @Previewable @State var place: Place = Place(sdPlace: SDPlace.l1)
    @Previewable @State var editMode: PlaceDetailsContentView.EditMode = .none

    PlaceDetailsContentView(place: $place, editMode: $editMode)
}
#endif
*/
