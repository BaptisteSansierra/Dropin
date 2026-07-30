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
            if viewModel.places.count > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.pushGroupMapView()
                    } label: {
                        Image(systemName: "globe.europe.africa")
                    }
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
                .textCase(.uppercase)
                .padding(.leading)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .fill(.surface1)
                    .stroke(.fieldBorder)
                    .frame(height: 45)
                    .padding(.horizontal)
                TextField("common.group_name", text: $viewModel.group.name)
                    .textStyle(.body)
                    .background(.clear)
                    .padding(.vertical, 0)
                    .padding(.horizontal, 30)
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
                        .fill(viewModel.groupColor)
                        .stroke(.fieldBorder)
                        .frame(height: 25)
                        .frame(width: 100)
                        .padding(.leading, 30)
                    Spacer()
                    ColorPicker(String(""), selection: $viewModel.groupColor, supportsOpacity: false)
                        .labelsHidden()
                        .padding(.horizontal, 30)
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
                .textCase(.uppercase)
                .padding(.leading)
                .padding(.top, 10)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .fill(.surface1)
                    .stroke(.fieldBorder)
                    .frame(height: 45)
                    .padding(.horizontal)
                
                HStack {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerSize: 8)
                            .fill(viewModel.group.color.opacity(0.15))
                            .strokeBorder(.fieldBorder)
                            .frame(height: 30)
                            .frame(width: 30)
                            .foregroundStyle(.clear)
                        IconView(icon: viewModel.group.icon)
                            .sizeCaption()
                    }
                    .padding(.leading, 30)
                    Spacer()
                    TextButton(text: "common.change", textStyle: .xSmallButton) {
                        viewModel.showingMarkerList.toggle()
                    }
                    .padding(.trailing, 30)
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
                        .padding(.leading)
                        .padding(.top, 10)
                    
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
                
                DestructiveButton(text: "common.delete_group", style: .bordered) {
                    viewModel.showingRemoveAlert = true
                }
                .padding(.horizontal)
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
    .environment(AppSettings())
}

#endif
