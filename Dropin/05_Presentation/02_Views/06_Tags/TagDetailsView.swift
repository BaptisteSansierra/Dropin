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
    @Binding private var tag: TagUI
    @State private var tagColor: Color
    @State private var showingRemoveAlert: Bool = false
    
    // MARK: - Env
    @Environment(\.dismiss) private var dismiss
    
    var blurEffectHeight: CGFloat {
        DropinApp.ui.button.height + 50 + UIApplication.rootBottomSafeArea()
    }
    
    // MARK: - Init
    init(viewModel: TagDetailsViewModel, tag: Binding<TagUI>) {
        self.viewModel = viewModel
        self._tag = tag
        self._tagColor = State(initialValue: tag.wrappedValue.color)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    TagView(name: tag.name, color: tag.color)
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
                try await viewModel.fetchPlace(tag.id)
            } catch {
                // TODO: error
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background(.backgroundSecondary)
        .alert("alert.remove_tag_title",
               isPresented: $showingRemoveAlert) {
            Button("common.cancel", role: .cancel) { }
            Button("common.delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteTag(tag)
                        dismiss()
                    } catch {
                        Log.error("Could not delete tag \(tag.name): \(error)")
                    }
                }
            }
        } message: {
            if viewModel.places.count > 0 {
                Text("alert.remove_tag_body_\(tag.name)_\(viewModel.places.count)")
            } else {
                Text("alert.remove_tag_empty_body_\(tag.name)")
            }
        }
    }
    
    // MARK: - Subviews
    private var nameView: some View {
        VStack(alignment: .leading) {
            Text("common.tag_name")
                .textStyle(.formSectionTitle2)
                .padding(.leading, 40)
            ZStack {
                RoundedRectangle(cornerSize: 8)
                    .frame(height: 45)
                    .foregroundStyle(.backgroundPrimary)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                TextField("common.tag_name", text: $tag.name)
                    .textStyle(.body)
                    .background(.clear)
                    .padding(.vertical, 0)
                    .padding(.horizontal, 40)
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
                        .foregroundStyle(tagColor)
                        .padding(.leading, 40)
                    //.padding(.trailing, 40)
                    Spacer()
                    ColorPicker(String(""), selection: $tagColor, supportsOpacity: false)
                        .labelsHidden()
                        .padding(.leading, 40)
                        .padding(.trailing, 40)
                        .onChange(of: tagColor) { oldValue, newValue in
                            tag.color = tagColor
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
                        .padding(.leading, 40)
                        .padding(.top, 30)
                    Divider()
                    List {
                        ForEach(viewModel.places) { place in
                            PlaceRowView(place: place, locationManager: viewModel.locationManager)
                                .swipeActions(allowsFullSwipe: false) {
                                    Button() {
                                        guard let idx = viewModel.places.firstIndex(where: { place.id == $0.id }) else { return }
                                        guard let tagIdx = place.tags.firstIndex(where: { tag.id == $0.id }) else { return }
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
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear
                            .frame(height: blurEffectHeight - UIApplication.rootBottomSafeArea())
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
                
                DestructiveButton(text: "common.delete_tag") {
                    showingRemoveAlert = true
                }
                .padding(.bottom, UIApplication.rootBottomSafeArea())
            }
        }
    }
    
    // MARK: private methods
    private func updateTag() {
        Task {
            do {
                try await viewModel.updateTag(tag)
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
}


#if DEBUG

struct MockTagDetailsView: View {
    var mock: MockContainer
    @State private var tag: TagUI

    var body: some View {
        mock.appContainer.createTagDetailsView(tag: $tag)
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
}

#endif
