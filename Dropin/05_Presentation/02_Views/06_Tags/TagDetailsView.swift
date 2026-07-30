//
//  TagDetailsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 12/9/25.
//

import SwiftUI

struct TagDetailsView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: TagDetailsViewModel
    
    // MARK: - Env
    @Environment(\.dismiss) private var dismiss
    
    var blurEffectHeight: CGFloat {
        DropinApp.ui.button.height + 50 + UIApplication.rootBottomSafeArea()
    }
    
    // MARK: - Init
    init(viewModel: TagDetailsViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    TagView(name: viewModel.tag.name,
                            color: viewModel.tag.color)
                    Spacer()
                }
                .padding(.top, 15)
                .padding(.bottom, 20)
                
                nameView
                
                colorView
                
                placesView
                
                Spacer()
            }
            deleteButton
        }
        .task {
            do {
                try await viewModel.fetchPlace()
            } catch {
                // TODO: error
            }
        }
        .toolbar {
            if viewModel.places.count > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.pushTagMapView(tagId: viewModel.tag.id)
                    } label: {
                        Image(systemName: "globe.europe.africa")
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background(.backgroundSecondary)
        .alert("alert.remove_tag_title",
               isPresented: $viewModel.showingRemoveAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("common.delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.softDeleteTag()
                        dismiss()
                    } catch {
                        Log.error("Could not delete tag \(viewModel.tag.name): \(error)")
                    }
                }
            }
        } message: {
            if viewModel.places.count > 0 {
                Text("alert.remove_tag_body_\(viewModel.tag.name)_\(viewModel.places.count)")
            } else {
                Text("alert.remove_tag_empty_body_\(viewModel.tag.name)")
            }
        }
    }
    
    // MARK: - Subviews
    private var nameView: some View {
        VStack(alignment: .leading) {
            Text("common.tag_name")
                .textStyle(.formSectionTitle2)
                .textCase(.uppercase)
                .padding(.leading)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .fill(.surface1)
                    .stroke(.fieldBorder)
                    .frame(height: 45)
                    .padding(.horizontal)
                TextField("common.tag_name", text: $viewModel.tag.name)
                    .textStyle(.body)
                    .background(.clear)
                    .padding(.vertical, 0)
                    .padding(.horizontal, 30)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        updateTag()
                    }
            }
        }
    }
    
    private var colorView: some View {
        VStack(alignment: .leading) {
            Text("common.tag_color")
                .textStyle(.formSectionTitle2)
                .textCase(.uppercase)
                .padding(.leading)
                .padding(.top, 10)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .fill(.surface1)
                    .stroke(.fieldBorder)
                    .frame(height: 45)
                    .padding(.horizontal)
                HStack() {
                    RoundedRectangle(cornerSize: 8)
                        .fill(viewModel.tagColor)
                        .frame(height: 25)
                        .frame(width: 100)
                        .padding(.leading, 30)
                    Spacer()
                    ColorPicker(String(""), selection: $viewModel.tagColor, supportsOpacity: false)
                        .labelsHidden()
                        .padding(.leading, 40)
                        .padding(.trailing, 40)
                        .onChange(of: viewModel.tagColor) { oldValue, newValue in
                            viewModel.tag.color = viewModel.tagColor
                            updateTag()
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    private var placesView: some View {
        if viewModel.loadingPlaces {
            VStack(alignment: .leading) {
                ProgressView()
            }
        } else {
            VStack(alignment: .leading) {
                if viewModel.places.count > 0 {
                    Text("common.related_places")
                        .textStyle(.formSectionTitle2)
                        .textCase(.uppercase)
                        .padding(.horizontal)
                        .padding(.top)
                    //Divider()
                    
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.places) { place in
                                placeRow(place)
                            }
                        }
                        .padding(.top, 5)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .scrollContentBackground(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: blurEffectHeight - UIApplication.rootBottomSafeArea())
                    }
                    // Selected place sheet
                    .sheet(item: $viewModel.selectedPlaceId,
                           onDismiss: {
                        viewModel.selectedPlaceId = nil
                    }) { placeId in
                        createPlaceDetailsSheetView()
                            .presentationDetents([.medium, .large])
                            .presentationCornerRadius(20)
                            .presentationBackground(.backgroundPrimary)
                    }
                } else {
                    Text("common.no_related_places")
                        .textStyle(.formSectionTitle2)
                        .padding(.leading, 40)
                        .padding(.top, 30)
                }
            }
        }
    }

    private func placeRow(_ place: PlaceUI) -> some View {
        PlaceRowView(place: place, locationManager: viewModel.locationManager)
            .swipeActions(allowsFullSwipe: false) {
                Button() {
                    guard let idx = viewModel.places.firstIndex(where: { place.id == $0.id }) else { return }
                    guard let tagIdx = place.tags.firstIndex(where: { viewModel.tag.id == $0.id }) else { return }
                    // Remove the place from tag list so UI is updated
                    viewModel.places.remove(at: idx)
                    // Remove the tag in place list and update the database from it
                    place.tags.remove(at: tagIdx)
                    updatePlace(place)
                } label: {
                    Text("common.unlink")
                }
                .tint(.destructive)
            }
            .onTapGesture {
                viewModel.selectedPlaceId = place.id
            }
    }

    private var deleteButton: some View {
        VStack(alignment: .center) {
            Spacer()
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(LinearGradient(colors: [.clear, // top → no blur visible
                                                  .black.opacity(0.7),
                                                  .black.opacity(0.9),
                                                  .black,
                                                  .black,
                                                  .black,
                                                  .black], // bottom → full blur visible
                                         startPoint: .top,
                                         endPoint: .bottom))
                    .frame(height: blurEffectHeight)
                
                DestructiveButton(text: "common.delete_tag", style: .bordered) {
                    viewModel.showingRemoveAlert = true
                }
                .padding(.horizontal)
                .padding(.bottom, UIApplication.rootBottomSafeArea())
            }
        }
    }
    
    // MARK: private methods
    private func updateTag() {
        Task {
            do {
                try await viewModel.updateTag()
            } catch {
                // TODO: handle error
                assertionFailure("Could not update tag: \(error)")
            }
        }
    }
    
    private func updatePlace(_ place: PlaceUI) {
        Task {
            do {
                try await viewModel.updatePlace(place)
            } catch {
                // TODO: handle error
                assertionFailure("Could not update place: \(error)")
            }
        }
    }
    
    private func createPlaceDetailsSheetView() -> PlaceSheetView {
        guard let selectedPlaceId = viewModel.selectedPlaceId else {
            fatalError("selectedPlaceId undefined")
        }
        guard let index = viewModel.places.firstIndex(where: { $0.id == selectedPlaceId }) else {
            fatalError("couldn't find place with id \(selectedPlaceId)")
        }
        return viewModel.createPlaceSheetView(place: $viewModel.places[index])
    }
}


#if DEBUG

struct MockTagDetailsView: View {
    var mock: MockContainer
    @State private var tag: TagUI

    var body: some View {
        mock.appContainer.createTagDetailsView(tag: tag)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.tag = mock.getTagUI(1)
    }
}

#Preview {
    NavigationStack {
        MockTagDetailsView()
    }
    .environment(AppSettings())
}

#endif
