//
//  PlaceDetailsSheetView.swift
//  Dropin
//
//  Created by baptiste sansierra on 14/8/25.
//

import SwiftUI

struct PlaceDetailsSheetView: View {
    
    // MARK: - State & Bindings
    @State private var place: Place
    @State private var editMode: PlaceDetailsContentView.EditMode = .none

    // MARK: - Dependencies
    @Environment(\.dismiss) var dismiss
    @Environment(NavigationContext.self) var navigationContext

    // MARK: - Body
    var body: some View {
        @Bindable var navigationContext = navigationContext

        VStack(alignment: .center, spacing: 0) {
            PlaceDetailsContentView(place: $place, editMode: $editMode)
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
            // Footer
            ZStack(alignment: .center) {
                Rectangle()
                    .foregroundStyle(.white)
                    .frame(height: 60)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: -5)
                footer
            }
        }
        .alert("alert.address_copied_title",
               isPresented: $navigationContext.showingAddressToClipboard,
               actions: {
            Button("common.ok", role: .cancel) { }
        },
               message: {
            Text("alert.address_copied_body")
        })
    }
    
    private var footer: some View {
        HStack(alignment: .center, spacing: 15) {
            // Go button
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .foregroundStyle(.dropinPrimary)
                    .frame(height: DropinApp.ui.button.height)
                Text("common.go")
                    .foregroundStyle(.white)
            }
            .padding(.leading, 15)
            .onTapGesture { onPressGo() }
            // Edit button
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .foregroundStyle(.dropinPrimary)
                    .frame(height: DropinApp.ui.button.height)
                Text("common.edit")
                    .foregroundStyle(.white)
            }
            .padding(.trailing, 15)
            .onTapGesture { onPressEdit() }
        }
    }

    // MARK: - init
    init(place: Place) {
        self._place = State(initialValue: place)
    }
    
    // MARK: - Actions
    private func onPressGo() {
        print("TODO : open MAP")
    }
    
    private func onPressEdit() {
        dismiss()
        navigationContext.navigationPath.append(place.getSeed())
    }
}
