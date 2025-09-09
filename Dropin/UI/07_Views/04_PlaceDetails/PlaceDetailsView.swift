//
//  PlaceDetailsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/8/25.
//

import SwiftUI

struct PlaceDetailsView: View {
    
    // MARK: - State & Bindings
    @State private var place: Place
    @State private var editMode: PlaceDetailsContentView.EditMode
    @State private var showingDeleteWarning = false

    // MARK: - Dependencies
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationContext.self) var navigationContext

    // MARK: - Body
    var body: some View {
        @Bindable var navigationContext = navigationContext
        
        VStack {
            PlaceDetailsContentView(place: $place, editMode: $editMode)
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
                    place.applyChanges()
                    editMode = .none
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
    init(place: Place, editMode: PlaceDetailsContentView.EditMode = .none) {
        self._place = State(initialValue: place)
        self._editMode = State(initialValue: editMode)
    }
    
    // MARK: - Actions
    private func onPressDelete() {
        showingDeleteWarning.toggle()
    }
    
    private func cancelChanges() {
        place.reloadFromSeed()
    }
    
    private func onApplyChanges() {
        editMode = .apply
    }
    
    private func performDelete() {
        let sdPlace = place.getSeed()
        modelContext.delete(sdPlace)
        dismiss()
    }
}


#Preview {
    NavigationStack {
        PlaceDetailsView(place: Place(sdPlace: SDPlace.l1))
            .environment(NavigationContext())
    }
}
