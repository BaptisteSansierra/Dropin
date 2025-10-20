//
//  PlaceDetailsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/8/25.
//

import SwiftUI

struct PlaceDetailsView: View {

    // MARK: - State & Bindings
    @State private var viewModel: PlaceDetailsViewModel
    @Binding private var place: PlaceUI
    @State private var placeOrigin: PlaceUI?
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
        .task {
            self.placeOrigin = place.copy()
        }
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
                case .edit:
                    placeOrigin = place.copy()
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
        self._viewModel = State(initialValue: viewModel)
        self._place = place
        self._editMode = State(initialValue: editMode)
    }
    
    // MARK: - Actions
    private func onPressDelete() {
        showingDeleteWarning.toggle()
    }
    
    private func cancelChanges() {
        // reload from origin
        guard let placeOrigin = placeOrigin else { return }
        print("Origin name is \(placeOrigin.name)")
        print("Current name is \(place.name)")
        place = placeOrigin // PlaceMapper.toUI(placeOrigin)
        print("After reset - Current name is \(place.name)")
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

#if DEBUG
struct MockPlaceDetailsView: View {
    var mock: MockContainer
    @State var place: PlaceUI

    var body: some View {
        mock.appContainer.createPlaceDetailsView(place: $place, editMode: .edit)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.place = mock.getPlaceUI(1)
    }
}

#Preview {
    NavigationStack {
        MockPlaceDetailsView()
            .environment(NavigationContext())
    }
}

#endif
