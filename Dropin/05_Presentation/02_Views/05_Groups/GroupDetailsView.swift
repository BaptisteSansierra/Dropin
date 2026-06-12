//
//  GroupDetailsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/9/25.
//

import SwiftUI

struct GroupDetailsView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: GroupDetailsViewModel
    
    // MARK: - Env
    @Environment(\.dismiss) private var dismiss
    
    var blurEffectHeight: CGFloat {
        DropinApp.ui.button.height + 50 + UIApplication.rootBottomSafeArea()
    }
    
    // MARK: - Init
    init(viewModel: GroupDetailsViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    GroupView(group: viewModel.group)
                    Spacer()
                }
                .padding(.top, 15)
                .padding(.bottom, 20)
                
                nameView
                
                colorView
                
                iconView
                
                placesView
                
                Spacer()
            }
            deleteButton
        }
        .task {
            do {
                try await viewModel.fetchPlaces()
            } catch {
                // TODO: error
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background(.backgroundSecondary)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.pushGroupMapView()
                } label: {
                    Image(systemName: "globe.europe.africa")
                }
            }
        }
        .alert("alert.remove_group_title",
               isPresented: $viewModel.showingRemoveAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("common.delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.softDeleteGroup()
                        dismiss()
                    } catch {
                        Log.error("Could not delete group \(viewModel.group.name): \(error)")
                    }
                }
            }
        } message: {
            if viewModel.places.count > 0 {
                Text("alert.remove_group_body_\(viewModel.group.name)_\(viewModel.places.count)")
            } else {
                Text("alert.remove_group_empty_body_\(viewModel.group.name)")
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingMarkerList) {
            MarkerListView(selected: Binding<Icon>(
                get: {
                    return viewModel.group.icon
                }, set: { value in
                    viewModel.group.icon = value
                    Task {
                        try await viewModel.updateGroup()
                    }
                }))
        }
    }
    
    // MARK: - Subviews
    private var nameView: some View {
        VStack(alignment: .leading) {
            Text("common.group_name")
                .textStyle(.formSectionTitle2)
                .padding(.leading, 40)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .frame(height: 45)
                    .foregroundStyle(.backgroundPrimary)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                TextField("common.group_name", text: $viewModel.group.name)
                    .textStyle(.body)
                    .background(.clear)
                    .padding(.vertical, 0)
                    .padding(.horizontal, 40)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        updateGroup()
                    }
            }
        }
    }
    
    private var colorView: some View {
        VStack(alignment: .leading) {
            Text("common.group_color")
                .textStyle(.formSectionTitle2)
                .padding(.leading, 40)
                .padding(.top, 10)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .frame(height: 45)
                    .foregroundStyle(.backgroundPrimary)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                HStack() {
                    RoundedRectangle(cornerSize: 8)
                        .frame(height: 25)
                        .frame(width: 100)
                        .foregroundStyle(viewModel.groupColor)
                        .padding(.leading, 40)
                    //.padding(.trailing, 40)
                    Spacer()
                    ColorPicker(String(""), selection: $viewModel.groupColor, supportsOpacity: false)
                        .labelsHidden()
                        .padding(.leading, 40)
                        .padding(.trailing, 40)
                        .onChange(of: viewModel.groupColor) { oldValue, newValue in
                            viewModel.group.color = viewModel.groupColor
                            updateGroup()
                        }
                }
            }
        }
    }
    
    private var iconView: some View {
        VStack(alignment: .leading) {
            Text("common.group_symbol")
                .textStyle(.formSectionTitle2)
                .padding(.leading, 40)
                .padding(.top, 10)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .frame(height: 45)
                    .foregroundStyle(.backgroundPrimary)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                
                HStack {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerSize: 8)
                            .strokeBorder(.textPrimary, style: StrokeStyle(lineWidth: 1))
                            .frame(height: 25)
                            .frame(width: 100)
                            .foregroundStyle(.clear)
                        IconView(icon: viewModel.group.icon)
                            .sizeCaption()
                    }
                    .padding(.leading, 40)
                    Spacer()
                    IcoButton(systemImage: "ellipsis",
                              icoSize: 14,
                              action: { viewModel.showingMarkerList.toggle() })
                    .padding(0)
                    .padding(.trailing, 40)
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
                        .padding(.leading, 40)
                        .padding(.top, 30)
                    Divider()
                    List {
                        ForEach(viewModel.places) { place in
                            PlaceRowView(place: place, locationManager: viewModel.locationManager)
                                .swipeActions(allowsFullSwipe: false) {
                                    Button() {
                                        guard let idx = viewModel.places.firstIndex(where: { place.id == $0.id }) else { return }
                                        // Remove the place from group list so UI is updated
                                        viewModel.places.remove(at: idx)
                                        // Remove the group from place and update the database from it
                                        place.group = nil
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
                
                DestructiveButton(text: "common.delete_group") {
                    viewModel.showingRemoveAlert = true
                }
                .padding(.bottom, UIApplication.rootBottomSafeArea())
            }
        }
    }
    
    // MARK: private methods
    private func updateGroup() {
        Task {
            do {
                try await viewModel.updateGroup()
            } catch {
                // TODO: handle error
                assertionFailure("Could not delete update group")
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

struct MockGroupDetailsView: View {
    var mock: MockContainer
    @State private var group: GroupUI

    var body: some View {
        mock.appContainer.createGroupDetailsView(group: group)
    }
    
    init() {
        let mock = MockContainer()
        self.mock = mock
        self.group = mock.getGroupUI(2)
    }
}

#Preview {
    NavigationStack {
        MockGroupDetailsView()
    }
}

#endif
