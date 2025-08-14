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
                Button(editMode == .edit ? "Cancel" : "Edit") {
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
        .alert("Delete place '\(place.name)' ?",
               isPresented: $showingDeleteWarning,
               actions: {
            Button(role: .destructive) {
                performDelete()
            } label: {
                Text("Delete")
            }
            Button("Cancel", role: .cancel) { }
        }, message: {
            Text("This action cannot be undone!\nConfirm place deletion ?")
        })
        .alert("Copied !",
               isPresented: $navigationContext.showingAddressToClipboard,
               actions: {
            Button("Ok", role: .cancel) { }
        },
               message: {
            Text("Address was copied to clipboard")
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
            Text("Apply changes")
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
            Text("Delete place")
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
