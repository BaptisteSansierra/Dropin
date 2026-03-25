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
    @State private var place: PlaceUI
    @State private var showMissingName: Bool = false

    // To be moved in VM
    @State private var confirmCancel: Bool = false

    private var tagIds: [UUID]?
    private var groupId: UUID?

    // MARK: - Init
    init(viewModel: PlaceCreateViewModel,
         coordinates: CLLocationCoordinate2D,
         address: String,
         name: String,
         marker: String?,
         tags: [UUID],
         group: UUID?) {
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

    var body: some View {
        viewModel.body(place: $place, showMissingName: $showMissingName)
            .navigationBarBackButtonHidden(true)
            .toolbar { toolbar }
            .task {
                if let tagIds = tagIds {
                    place.tags = await viewModel.retrieveTags(tagIds: tagIds)
                }
                if let groupId = groupId {
                    place.group = await viewModel.retrieveGroup(groupId: groupId)
                }
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
            let name = place.name.trimmingCharacters(in: [" "])
            guard !name.isEmpty else {
                showMissingName = true
                return
            }
            guard !place.address.isEmpty else {
                assertionFailure("Place \(name) has an empty address")
                return
            }
            // Create new place
            do {
                try await viewModel.save(place: place)
                viewModel.popToRoot()

            } catch {
                // TODO: handle
                assertionFailure("Couldn't save: \(error)")
            }
        }
    }
    
    private func cancelEdits() {
        confirmCancel = true
    }
}

