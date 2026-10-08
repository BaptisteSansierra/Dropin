//
//  PlaceCreateView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/3/26.
//

import SwiftUI
import CoreLocation

struct PlaceCreateView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: PlaceCreateViewModel
    @State private var place: PlaceUIModel
    @State private var showMissingName: Bool = false
    @Environment(RootView.ActionBus.self) private var actionBus

    // To be moved in VM
    @State private var confirmCancel: Bool = false

    private var tagIds: [UUID]?
    private var categoryId: UUID?

    // MARK: - Init
//    init(viewModel: PlaceCreateViewModel,
//         coordinates: CLLocationCoordinate2D,
//         address: String?,
//         name: String,
//         marker: String?,
//         tags: [UUID],
//         category: UUID?) {
//        self._viewModel = State(initialValue: viewModel)
//        place = PlaceUIModel(coordinates: coordinates)
//        place.address = address
//        place.name = name
//        if let marker = marker {
//            place.icon = Icon(rawValue: marker)
//        }
//        self.tagIds = tags
//        self.categoryId = category
//    }

    init(viewModel: PlaceCreateViewModel,
         place: PlaceUIModel) {
        self._viewModel = State(initialValue: viewModel)
        self._place = State(initialValue: place)
    }

    
    var body: some View {
        viewModel.body(place: $place, showMissingName: $showMissingName)
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbar }
            .task {
//                if let tagIds = tagIds {
//                    place.tags = await viewModel.retrieveTags(tagIds: tagIds)
//                }
//                if let categoryId = categoryId {
//                    place.category = await viewModel.retrieveCategory(categoryId: categoryId)
//                }
            }
    }
    
    // MARK: - Subviews
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("common.cancel", action: cancelEdits)
                .tint(.blue)
                .confirmationDialog("dialog.cancel_creation.title",
                                    isPresented: $confirmCancel,
                                    titleVisibility: .visible,
                                    actions: {
                    Button("common.cancel", role: .destructive) {
                        viewModel.pop()
                    }
                    Button("common.keep_editing") {
                    }
                })
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("common.save", action: save)
                .tint(.blue)
        }
    }

    // MARK: - private methods
    private func save() {
        Task {
            // Ensure a name is given
            let name = place.name.trimmingCharacters(in: [" "])
            guard !name.isEmpty else {
                showMissingName = true
                return
            }
            // Remove empty contact fields
            place.phone.removeEmptyFields()
            place.email.removeEmptyFields()
            place.url.removeEmptyFields()
            // Create new place
            do {
                try await viewModel.save(place: place)
                actionBus.send(.reloadMainPlaces)
            } catch {
                // TODO: handle
                assertionFailure("Couldn't save: \(error)")
            }
        }
        viewModel.popToRoot()
    }
    
    private func cancelEdits() {
        confirmCancel = true
    }
}

