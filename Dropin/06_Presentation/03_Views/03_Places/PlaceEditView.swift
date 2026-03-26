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
            // Issue: iOS<26 NavigationBar bg is transparent but become visible when view is scrolled
            // Fix: if iOS<26 : hide nav bar, add overlay buttons
            .hideNavigationBarBelowIOS26()
            .overlay(content: {
                if #unavailable(iOS 26) {
                    toolbarView
                }
            })
            .toolbar {
                if #available(iOS 26, *) {
                    toolbar
                }
            }
            .onChange(of: editedPlace.changeToken) { oldValue, newValue in
                Log.debug("Place edited !! isEqual to source = \(editedPlace.isContentEqual(srcPlace))")
                edited = !editedPlace.isContentEqual(srcPlace)
            }
    }
    
    // MARK: - Subviews
    private var cancelButtonView: some View {
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
    
    private var applyButtonView: some View {
        Button("common.done", action: applyEdits)
            .disabled(!edited)
            .tint(.blue)
    }
    
    private var toolbarView: some View {
        VStack {
            HStack {
                cancelButtonView
                    .padding()
                Spacer()
                applyButtonView
                    .padding()
            }
            Spacer()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            cancelButtonView
        }
        ToolbarItem(placement: .topBarTrailing) {
            applyButtonView
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
        
        Log.debug("PLACE \(place.name) has GROUP \(place.group?.name)")
        
        //self.place = mock.getPlaceUI(1) // No group
    }
}

#Preview {
    NavigationStack {
        MockPlaceEditView(5)
    }
}

#endif
