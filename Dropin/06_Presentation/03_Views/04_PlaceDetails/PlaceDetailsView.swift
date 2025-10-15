//
//  PlaceDetailsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/8/25.
//

import SwiftUI

struct PlaceDetailsView: View {

    // MARK: - Properties
    private let viewModel: PlaceDetailsViewModel
    private let placeOrigin: PlaceEntity

    // MARK: - State & Bindings
    @Binding private var place: PlaceUI
    @State private var editMode: PlaceEditMode
    @State private var showingDeleteWarning = false

    // MARK: - Dependencies
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationContext.self) var navigationContext

    // MARK: - Body
    var body: some View {
        @Bindable var navigationContext = navigationContext
        
        VStack {
            viewModel.createPlaceDetailsContentView(place: $place, editMode: $editMode)
            //PlaceDetailsContentView(place: $place, editMode: $editMode)
            Spacer()
            if editMode == .edit {
                applyButton
            }
            deleteButton
        }
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(editMode == .edit ? "common.cancel" : "common.edit") {
                    switch editMode {
                        case .edit:
                            editMode = .cancel
                        case .none:
                            editMode = .edit
                        default:
                            ()
                    }
                }
                .tint(.dropinPrimary)
            }
        }
        .alert("alert.delete_place_title_\(place.name)",
               isPresented: $showingDeleteWarning,
               actions: {
            Button(role: .destructive) {
                performDelete()
            } label: {
                Text("common.delete")
            }
            Button("common.cancel", role: .cancel) { }
        }, message: {
            Text("alert.delete_place_msg")
        })
        .alert("alert.address_copied_title",
               isPresented: $navigationContext.showingAddressToClipboard,
               actions: {
            Button("common.ok", role: .cancel) { }
        },
               message: {
            Text("alert.address_copied_body")
        })
        .onChange(of: editMode) { oldValue, newValue in
            switch editMode {
                case .cancel:
                    cancelChanges()
                    editMode = .none
                case .apply:
                    Task {
                        do {
                            try await viewModel.updatePlace(place)
                        } catch {
                            assertionFailure("could not apply changes: \(error)")
                        }
                        editMode = .none
                    }
                default:
                    ()
            }
        }
    }
    
    // MARK: - Subviews
    private var applyButton: some View {
        ZStack {
            RoundedRectangle(cornerSize: 8)
                .foregroundStyle(.dropinPrimary)
                .frame(width: DropinApp.ui.button.width,
                       height: DropinApp.ui.button.height)
            Text("place_details.apply")
                .foregroundStyle(.white)
        }
        .padding(.bottom, 5)
        .onTapGesture { onApplyChanges() }
    }

    private var deleteButton: some View {
        ZStack {
            RoundedRectangle(cornerSize: 8)
                .foregroundStyle(.red)
                .frame(width: DropinApp.ui.button.width,
                       height: DropinApp.ui.button.height)
            Text("common.delete_place")
                .foregroundStyle(.white)
        }
        .padding(.bottom, 15)
        .onTapGesture { onPressDelete() }
    }

    // MARK: - init
    init(viewModel: PlaceDetailsViewModel, place: Binding<PlaceUI>, editMode: PlaceEditMode = .none) {
        self.viewModel = viewModel
        self._place = place
        self.placeOrigin = PlaceMapper.toDomain(place.wrappedValue)
        self._editMode = State(initialValue: editMode)
    }
    
    // MARK: - Actions
    private func onPressDelete() {
        showingDeleteWarning.toggle()
    }
    
    private func cancelChanges() {
        // reload fron origin
        place = PlaceMapper.toUI(placeOrigin)
    }
    
    private func onApplyChanges() {
        editMode = .apply
    }
    
    private func performDelete() {
        Task {
            do {
                navigationContext.navigationPath = NavigationPath()
                // Delay the deletion so the parentview navigation path does not contain a stale model
                try await Task.sleep(for: .seconds(0.5))
                try await viewModel.deletePlace(place)
            } catch {
                assertionFailure("Failed to delete place \(place.name)")
            }
        }
    }
}

/*
#if DEBUG
#Preview {
    NavigationStack {
        PlaceDetailsView(place: Place(sdPlace: SDPlace.l1))
            .environment(NavigationContext())
    }
}
#endif
*/
