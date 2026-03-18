//
//  PlaceEditView.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/2/26.
//

import SwiftUI

struct PlaceEditView: View {
    
    // MARK: - States & Bindings
    @State private var viewModel: PlaceEditViewModel
    @Binding private var srcPlace: PlaceUI
    @State private var showMissingName: Bool = false

    // To be moved in VM
    @State private var editedPlace: PlaceUI
    @State private var confirmCancel: Bool = false
    @State private var edited: Bool = false // true if contains some edits

    // MARK: - Init
    init(viewModel: PlaceEditViewModel, place: Binding<PlaceUI>) {
        self.viewModel = viewModel
        self._srcPlace = place
        self.editedPlace = place.wrappedValue.copy()
    }
    
    // MARK: - Body
    var body: some View {
        viewModel.body(place: $editedPlace, showMissingName: $showMissingName)
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbar }
//            .onChange(of: editedPlace) { oldValue, newValue in
//                print("Place edited !! isEqual to source = \(editedPlace.isContentEqual(srcPlace))")
//                edited = !editedPlace.isContentEqual(srcPlace)
//            }
            .onChange(of: editedPlace.changeToken) { oldValue, newValue in
                print("Place edited !! isEqual to source = \(editedPlace.isContentEqual(srcPlace))")
                edited = !editedPlace.isContentEqual(srcPlace)
            }
    }
    
    // MARK: - Subviews
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("common.cancel", action: cancelEdits)
                .tint(.blue)
                .confirmationDialog("dialog.cancel_edits.title",
                                    isPresented: $confirmCancel,
                                    titleVisibility: .visible,
                                    actions: {
                    Button("dialog.cancel_edits.discard", role: .destructive) {
                        editedPlace = srcPlace.copy()
                        viewModel.pop()
                    }
                    Button("dialog.cancel_edits.cancel") {
                    }
                })
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("common.done", action: applyEdits)
                .disabled(!edited)
                .tint(.blue)
        }
    }
    
    // MARK: - private methods
    private func applyEdits() {
        let name = editedPlace.name.trimmingCharacters(in: [" "])
        guard !name.isEmpty else {
            showMissingName = true
            return
        }
        guard !editedPlace.address.isEmpty else {
            assertionFailure("Place \(name) has an empty address")
            return
        }
        // Apply edits
        srcPlace = editedPlace
        Task {
            do {
                try await viewModel.updatePlace(editedPlace)
            } catch {
                assertionFailure("Couldn't update place \(editedPlace.name)")
            }
        }
        // Pop
        viewModel.pop()
    }
    
    private func cancelEdits() {
        guard edited else {
            viewModel.pop()
            return
        }
        // Ask confirmation if there's some edits
        confirmCancel = true
    }
}


#if DEBUG

struct MockPlaceEditView: View {
    var mock: MockContainer
    var index: Int
    @State var place: PlaceUI
    
    var body: some View {
        mock.appContainer.createPlaceEditView(place: $place)
    }
    
    init(_ index: Int) {
        self.index = index
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(index)
        
        print("PLACE \(place.name) has GROUP \(place.group?.name)")
        
        //self.place = mock.getPlaceUI(1) // No group
    }
}

#Preview {
    NavigationStack {
        MockPlaceEditView(5)
    }
}

#endif
